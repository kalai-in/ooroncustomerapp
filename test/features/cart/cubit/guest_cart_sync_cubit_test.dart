import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:customer/core/api/api_exception.dart';
import 'package:customer/features/cart/cubit/guest_cart_sync_cubit.dart';

import '../../../helpers/mock_cart_repository.dart';
import '../../../helpers/test_logging.dart';

void main() {
  late MockCartRepository repository;

  setUp(() => repository = MockCartRepository());

  tearDownAll(() => printTestDivider('=== All tests run! ==='));

  test('initial state is GuestCartSyncInitial', () {
    printTestDivider('GuestCartSyncCubit initial state is GuestCartSyncInitial');
    final cubit = GuestCartSyncCubit(repository: repository);
    expect(cubit.state, isA<GuestCartSyncInitial>());
    cubit.close();
  });

  blocTest<GuestCartSyncCubit, GuestCartSyncState>(
    'both lists empty short-circuits to Success("") immediately, no API call',
    build: () => GuestCartSyncCubit(repository: repository),
    act: (cubit) => cubit.bulkAddItems(
      quickVariantIds: [],
      quickQuantities: [],
      ecommerceVariantIds: [],
      ecommerceQuantities: [],
    ),
    expect: () {
      printTestDivider('bulkAddItems both empty → immediate Success(""), no API call');
      return [isA<GuestCartSyncSuccess>().having((s) => s.message, 'message', '')];
    },
    verify: (_) {
      verifyNever(
        () => repository.bulkAddToCart(
          quickVariantIds: any(named: 'quickVariantIds'),
          quickQuantities: any(named: 'quickQuantities'),
          ecommerceVariantIds: any(named: 'ecommerceVariantIds'),
          ecommerceQuantities: any(named: 'ecommerceQuantities'),
        ),
      );
    },
  );

  blocTest<GuestCartSyncCubit, GuestCartSyncState>(
    'having only one list non-empty still calls the repository',
    setUp: () {
      when(
        () => repository.bulkAddToCart(
          quickVariantIds: any(named: 'quickVariantIds'),
          quickQuantities: any(named: 'quickQuantities'),
          ecommerceVariantIds: any(named: 'ecommerceVariantIds'),
          ecommerceQuantities: any(named: 'ecommerceQuantities'),
        ),
      ).thenAnswer((_) async => 'Merged');
    },
    build: () => GuestCartSyncCubit(repository: repository),
    act: (cubit) => cubit.bulkAddItems(
      quickVariantIds: ['1'],
      quickQuantities: ['1'],
      ecommerceVariantIds: [],
      ecommerceQuantities: [],
    ),
    expect: () {
      printTestDivider('bulkAddItems one non-empty list still calls repository');
      return [isA<GuestCartSyncLoading>(), isA<GuestCartSyncSuccess>()];
    },
    verify: (_) {
      verify(
        () => repository.bulkAddToCart(
          quickVariantIds: ['1'],
          quickQuantities: ['1'],
          ecommerceVariantIds: [],
          ecommerceQuantities: [],
        ),
      ).called(1);
    },
  );

  blocTest<GuestCartSyncCubit, GuestCartSyncState>(
    'emits Loading then Success(message) on success',
    setUp: () {
      when(
        () => repository.bulkAddToCart(
          quickVariantIds: any(named: 'quickVariantIds'),
          quickQuantities: any(named: 'quickQuantities'),
          ecommerceVariantIds: any(named: 'ecommerceVariantIds'),
          ecommerceQuantities: any(named: 'ecommerceQuantities'),
        ),
      ).thenAnswer((_) async => 'Cart merged');
    },
    build: () => GuestCartSyncCubit(repository: repository),
    act: (cubit) => cubit.bulkAddItems(
      quickVariantIds: ['1'],
      quickQuantities: ['1'],
      ecommerceVariantIds: ['2'],
      ecommerceQuantities: ['3'],
    ),
    expect: () {
      printTestDivider('bulkAddItems emits Loading then Success(message)');
      return [
        isA<GuestCartSyncLoading>(),
        isA<GuestCartSyncSuccess>().having((s) => s.message, 'message', 'Cart merged'),
      ];
    },
  );

  blocTest<GuestCartSyncCubit, GuestCartSyncState>(
    'surfaces the ApiException message on failure',
    setUp: () {
      when(
        () => repository.bulkAddToCart(
          quickVariantIds: any(named: 'quickVariantIds'),
          quickQuantities: any(named: 'quickQuantities'),
          ecommerceVariantIds: any(named: 'ecommerceVariantIds'),
          ecommerceQuantities: any(named: 'ecommerceQuantities'),
        ),
      ).thenThrow(const ApiException(message: 'Merge failed'));
    },
    build: () => GuestCartSyncCubit(repository: repository),
    act: (cubit) => cubit.bulkAddItems(
      quickVariantIds: ['1'],
      quickQuantities: ['1'],
      ecommerceVariantIds: [],
      ecommerceQuantities: [],
    ),
    expect: () {
      printTestDivider('bulkAddItems surfaces the ApiException message');
      return [
        isA<GuestCartSyncLoading>(),
        isA<GuestCartSyncError>().having((s) => s.message, 'message', 'Merge failed'),
      ];
    },
  );

  blocTest<GuestCartSyncCubit, GuestCartSyncState>(
    'falls back to the localized message on a generic error',
    setUp: () {
      when(
        () => repository.bulkAddToCart(
          quickVariantIds: any(named: 'quickVariantIds'),
          quickQuantities: any(named: 'quickQuantities'),
          ecommerceVariantIds: any(named: 'ecommerceVariantIds'),
          ecommerceQuantities: any(named: 'ecommerceQuantities'),
        ),
      ).thenThrow(Exception('boom'));
    },
    build: () => GuestCartSyncCubit(repository: repository),
    act: (cubit) => cubit.bulkAddItems(
      quickVariantIds: ['1'],
      quickQuantities: ['1'],
      ecommerceVariantIds: [],
      ecommerceQuantities: [],
    ),
    expect: () {
      printTestDivider('bulkAddItems falls back to localized message on generic error');
      return [isA<GuestCartSyncLoading>(), isA<GuestCartSyncError>()];
    },
  );

  test('reset() emits GuestCartSyncInitial', () async {
    printTestDivider('reset() emits GuestCartSyncInitial');
    when(
      () => repository.bulkAddToCart(
        quickVariantIds: any(named: 'quickVariantIds'),
        quickQuantities: any(named: 'quickQuantities'),
        ecommerceVariantIds: any(named: 'ecommerceVariantIds'),
        ecommerceQuantities: any(named: 'ecommerceQuantities'),
      ),
    ).thenThrow(const ApiException(message: 'x'));
    final cubit = GuestCartSyncCubit(repository: repository);
    await cubit.bulkAddItems(
      quickVariantIds: ['1'],
      quickQuantities: ['1'],
      ecommerceVariantIds: [],
      ecommerceQuantities: [],
    ); // land in Error first

    cubit.reset();

    printTestLog('state → expected: GuestCartSyncInitial, actual: ${cubit.state}');
    expect(cubit.state, isA<GuestCartSyncInitial>());
    cubit.close();
  });
}
