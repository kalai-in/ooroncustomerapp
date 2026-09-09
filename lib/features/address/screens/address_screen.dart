import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/cubit/connectivity_cubit.dart';
import 'package:customer/commons/widgets/app_no_internet_widget.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/commons/widgets/paginated_list_footer.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/utils/pagination_scroll_controller.dart';
import 'package:customer/features/address/cubit/address_cubit.dart';
import 'package:customer/features/address/cubit/delete_address_cubit.dart';
import 'package:customer/features/address/models/address_model.dart';
import 'package:customer/features/address/widgets/add_new_address_button.dart';
import 'package:customer/features/address/widgets/address_actions.dart';
import 'package:customer/features/address/widgets/address_card.dart';
import 'package:customer/features/address/widgets/address_list_skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/constants/theme_constants.dart';

typedef AddressPaginationState = PaginationState<AddressData>;
typedef AddressLoaded = PaginationLoaded<AddressData>;
typedef AddressError = PaginationError<AddressData>;
typedef AddressLoading = PaginationLoading<AddressData>;

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  late final _pager = PaginationScrollController(
    onLoadMore: () => context.read<AddressCubit>().fetchMore(),
  );

  @override
  void initState() {
    super.initState();
    context.read<AddressCubit>().fetchInitial();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _goToAdd() => openAddressEditor(context);

  void _goToEdit(AddressData address) =>
      openAddressEditor(context, address: address);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<AddressCubit>().fetchInitial();
        }
      },
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityDisconnected;
        return BlocListener<DeleteAddressCubit, DeleteAddressState>(
          listener: (context, state) {
            if (state is DeleteAddressSuccess) {
              context.read<AddressCubit>().removeLocally(state.id);
            } else if (state is DeleteAddressError) {
              AppSnackBar.show(
                context: context,
                message: state.message,
                type: SnackBarType.error,
              );
            }
          },
          child: AppScaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: CustomAppBar(
              title: context.translate(LanguageLabelKeys.myAddresses),
            ),
            // Offline replaces the body only, so the app bar's back button
            // keeps working.
            body: isOffline
                ? const AppNoInternetView()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          ThemeConstants.paddingL,
                          ThemeConstants.paddingM,
                          ThemeConstants.paddingL,
                          0,
                        ),
                        child: AddNewAddressButton(onTap: _goToAdd),
                      ),
                      Expanded(
                        child:
                            BlocBuilder<AddressCubit, AddressPaginationState>(
                              builder: (context, state) {
                                if (state is AddressLoading) {
                                  return const AddressListSkeletonLoader();
                                }
                                if (state is AddressError) {
                                  return EmptyStateWidget(
                                    imagePath: AssetsConstants.noAddressFound,
                                    title: state.message,
                                    subtitle: context.translate(
                                      LanguageLabelKeys.pullToRefresh,
                                    ),
                                    onRetry: () =>
                                        context.read<AddressCubit>().refresh(),
                                  );
                                }
                                if (state is AddressLoaded) {
                                  return _buildList(context, state);
                                }
                                return AppSpacing.shrink;
                              },
                            ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, AddressLoaded state) {
    if (state.data.isEmpty) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noAddressFound,
        title: context.translate(LanguageLabelKeys.noAddressesFound),
        subtitle: context.translate(LanguageLabelKeys.addAddressPrompt),
      );
    }

    return RefreshIndicator(
      color: context.cs.primary,
      onRefresh: () async => context.read<AddressCubit>().refresh(),
      child: ListView.builder(
        controller: _pager.controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingM, ThemeConstants.paddingL, ThemeConstants.paddingL),
        itemCount: state.data.length + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.data.length) {
            return PaginatedListFooter(
              isLoadingMore: state.isFetchingMore,
              hasMore: state.hasMore,
            );
          }
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10),
            child: AddressCard(
              address: state.data[index],
              onEdit: () => _goToEdit(state.data[index]),
              onDelete: () => confirmDeleteAddress(context, state.data[index]),
            ),
          );
        },
      ),
    );
  }
}
