import 'package:customer/features/auth/models/auth_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/local_storage/auth_hive_box.dart';
import '../repositories/auth_repository.dart';
import 'package:customer/commons/cubit/api_error_guard.dart';

// ── States ──────────────────────────────────────────────────────────────────
sealed class CustomSmsVerifyPhoneOtpState {}

final class CustomSmsVerifyPhoneOtpInitial
    extends CustomSmsVerifyPhoneOtpState {}

final class CustomSmsVerifyPhoneOtpLoading
    extends CustomSmsVerifyPhoneOtpState {}

final class CustomSmsVerifyPhoneOtpLoaded extends CustomSmsVerifyPhoneOtpState {
  final AuthModel user;
  CustomSmsVerifyPhoneOtpLoaded(this.user);
}

final class CustomSmsVerifyPhoneOtpError extends CustomSmsVerifyPhoneOtpState {
  final String message;
  CustomSmsVerifyPhoneOtpError(this.message);
}

// ── Cubit ────────────────────────────────────────────────────────────────────
class CustomSmsVerifyPhoneOtpCubit extends Cubit<CustomSmsVerifyPhoneOtpState>
    with ApiErrorGuard<CustomSmsVerifyPhoneOtpState> {
  final AuthRepository _repository;

  CustomSmsVerifyPhoneOtpCubit({AuthRepository? repository})
    : _repository = repository ?? AuthRepository(),
      super(CustomSmsVerifyPhoneOtpInitial());

  Future<void> customSmsVerifyPhoneOtp({
    required String phoneNumber,
    required String otp,
    required String countryCode,
  }) async {
    emit(CustomSmsVerifyPhoneOtpLoading());
    await guard(() async {
      final user = await _repository.customSmsVerifyPhoneOtp(
        phoneNumber: phoneNumber,
        otp: otp,
        countryCode: countryCode,
      );
      await AuthHiveBox.instance.saveLoginData(userLogin: user);
      emit(CustomSmsVerifyPhoneOtpLoaded(user));
    }, onError: (msg) => emit(CustomSmsVerifyPhoneOtpError(msg)));
  }

  void reset() => emit(CustomSmsVerifyPhoneOtpInitial());
}
