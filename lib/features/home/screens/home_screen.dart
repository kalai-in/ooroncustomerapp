import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/features/cart/cubit/cart_action_cubit.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/features/category/cubit/sub_category_cubit.dart';
import 'package:customer/features/category/cubit/sub_category_selection_cubit.dart';
import 'package:customer/features/category/models/category_model.dart';
import 'package:customer/features/category/screens/sub_category_screen.dart';
import 'package:customer/features/products/cubit/filter_cubit.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/services/notification_service.dart';
import 'package:customer/features/address/widgets/location_permission_dialog.dart';
import 'package:customer/commons/cubit/country_settings_cubit.dart';
import 'package:customer/commons/cubit/location_cubit.dart';
import 'package:customer/features/home/cubits/home_layout_cubit.dart';
import 'package:customer/features/home/models/home_builder_model.dart';
import 'package:customer/features/home/models/enums/home_type.dart';
import 'package:customer/features/home/utils/home_hex_color.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/home/widgets/home_app_bar_delegate.dart';
import 'package:customer/features/location/widgets/location_required_view.dart';
import 'package:customer/commons/widgets/popup_dialog.dart';
import 'package:customer/features/home/widgets/home_section_widget.dart';
import 'package:customer/features/home/widgets/home_skeleton_loader.dart';
import 'package:customer/commons/widgets/store_closed_banner.dart';
import 'package:customer/features/location/screens/location_search_screen.dart';
import 'package:customer/features/location/screens/location_setup_sheet.dart';
import 'package:customer/features/products/cubit/product_cubit.dart';
import 'package:customer/features/products/screens/product_screen.dart';
import 'package:customer/features/main/cubit/nav_cubit.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';

List<Color> _defaultGradient(ThemeData theme) {
  final primary = theme.primaryColor;
  return [primary, primary];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  int _selectedMode = 0;
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);
  double _lastScrollOffset = 0;
  List<CategoryTabs> _categoryTabs = [];
  String _layoutMode = '';
  HomeType _homeType = HomeType.unknown;
  Layout? _layout;
  String? _timeToDeliver;
  String? _distance;
  String? _channelLabelQuick;
  String? _channelLabelEcommerce;
  List<String>? _searchSuggestions;

  static const double _kScrollThreshold = 80.0;

  List<Color> _gradient(ThemeData theme) => _defaultGradient(theme);

  // Mirrors HomeAppBarDelegate's own background resolution so the
  // pull-to-refresh spinner matches whatever the header is currently
  // showing (per-tab brand color / single-layout color) instead of
  // always defaulting to the theme's primary color.
  Color _currentHeaderColor(ThemeData theme) {
    if (_homeType == HomeType.single) {
      return parseHomeHexColor(_layout?.backgroundColor) ?? theme.primaryColor;
    }
    final idx = _tabController?.index ?? 0;
    final tab = (_categoryTabs.isNotEmpty && idx < _categoryTabs.length)
        ? _categoryTabs[idx]
        : null;
    return parseHomeHexColor(tab?.backgroundColor) ?? theme.primaryColor;
  }

  String _locationLabel = '';
  String _locationAddress = '';
  bool _isCheckingPermission = false;

  void _loadLocation() {
    final hive = SettingsHiveBox.instance;
    setState(() {
      _locationLabel = hive.locationLabel.isNotEmpty
          ? hive.locationLabel
          : context.translate(LanguageLabelKeys.setLocation);
      _locationAddress = hive.locationAddress;
    });
  }

  Future<void> _openLocationSheet() async {
    await showLocationSetupSheet(context);
    _loadLocation();
    if (mounted && SettingsHiveBox.instance.hasLocation) {
      context.read<HomeLayoutCubit>().loadHomeLayout();
      context.read<LocationCubit>().notifyLocationChanged();
    }
  }

  Future<void> _openLocationSearch() async {
    final saved = await AppNavigator.push<bool>(
      context,
      const LocationSearchScreen(),
    );
    if (!mounted) return;
    _loadLocation();
    if (saved == true && SettingsHiveBox.instance.hasLocation) {
      context.read<HomeLayoutCubit>().loadHomeLayout();
      context.read<LocationCubit>().notifyLocationChanged();
    }
  }

  void _onLocationConfirmed() {
    _loadLocation();
    if (mounted && SettingsHiveBox.instance.hasLocation) {
      context.read<HomeLayoutCubit>().loadHomeLayout();
      context.read<LocationCubit>().notifyLocationChanged();
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    if (_isCheckingPermission || !mounted) return;
    _isCheckingPermission = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }

      if (permission == LocationPermission.deniedForever) {
        await showLocationPermissionDialog(context);
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (!SettingsHiveBox.instance.hasLocation) {
          await _openLocationSheet();
        }
      }
    } finally {
      _isCheckingPermission = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadLocation();
    _selectedMode = SettingsHiveBox.instance.channel == 'ecommerce' ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) context.read<HomeLayoutCubit>().loadHomeLayout();
      if (!mounted) return;
      await _checkAndRequestLocationPermission();
      if (!mounted) return;
      await NotificationService.instance.requestPermission();
      if (mounted) PopupDialog.maybeShow(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLocation();
  }

  // Mirrors HomeAppBarDelegate.minExtent (topPadding + _searchH) so the
  // floating button sits flush under the pinned header regardless of
  // whether category tabs are showing.
  double _headerMinExtent(BuildContext context) {
    final topPadding = context.topSafePadding;
    final screenHeight = context.screenHeight;
    final searchH = _categoryTabs.isEmpty
        ? screenHeight * 0.045 + 22
        : screenHeight * 0.1075 + 40;
    return topPadding + searchH;
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final scrollingUp = offset < _lastScrollOffset;
    _lastScrollOffset = offset;

    final shouldShow = offset > _kScrollThreshold && scrollingUp;
    if (shouldShow != _isScrolled.value) _isScrolled.value = shouldShow;
  }

  String? _categoryIdAt(int index) {
    if (_homeType != HomeType.categoryWise) return null;
    if (_categoryTabs.isEmpty || index >= _categoryTabs.length) return null;
    // null id — no category filter
    return _categoryTabs[index].id;
  }

  // Data load + scroll-to-top for category switches are handled by
  // HomeAppBarDelegate.onCategoryTabTap (fires immediately on tap), not
  // here — a controller listener only fires after the tab indicator's
  // switch animation settles (~300ms later), which reads as a lag.
  TabController _makeTabController(int count) {
    return TabController(length: count, vsync: this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _tabController?.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  Widget _buildSections(BuildContext context, List<Sections> sections) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          ...sections.map(
            (s) => HomeSectionWidget(
              section: s,
              onCategoryTap: (cat) {
                if (cat.id == null) return;
                final category = Category(
                  id: cat.id.toString(),
                  name: cat.name,
                  imageUrl: cat.imageUrl,
                  hasChild: cat.hasChild ?? false,
                );
                if (category.hasChild == true) {
                  AppNavigator.push(
                    context,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) =>
                              SubCategoryCubit(parentCategoryId: category.id!),
                        ),
                        BlocProvider(
                          create: (_) => SubCategorySelectionCubit(),
                        ),
                        BlocProvider(create: (_) => SubCategoryChildrenCubit()),
                        BlocProvider(create: (_) => ProductCubit()),
                        BlocProvider(create: (_) => FilterCubit()),
                      ],
                      child: SubCategoryScreen(parentCategory: category),
                    ),
                  );
                } else {
                  AppNavigator.push(
                    context,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) =>
                              SubCategoryCubit(parentCategoryId: category.id!),
                        ),
                        BlocProvider(
                          create: (_) =>
                              ProductCubit()
                                ..loadProducts(categoryId: category.id!),
                        ),
                        BlocProvider(
                          create: (_) =>
                              FilterCubit()
                                ..loadFilters(categoryId: category.id!),
                        ),
                      ],
                      child: SubCategoryScreen(
                        parentCategory: category,
                        showSidebar: false,
                      ),
                    ),
                  );
                }
              },
              onProductTap: (product) {
                if (product.id != null) {
                  AppNavigator.pushNamed(
                    context,
                    RouteNames.productDetail,
                    arguments: product.id,
                  );
                }
              },
              onBrandTap: (brand) {
                if (brand.id == null) return;
                AppNavigator.push(
                  context,
                  BlocProvider(
                    create: (_) => ProductCubit(),
                    child: ProductScreen(
                      title: brand.name?.isNotEmpty == true
                          ? brand.name!
                          : context.translate(LanguageLabelKeys.viewMore),
                      brandId: brand.id.toString(),
                    ),
                  ),
                );
              },
              onViewMoreTap: (title, dataSource, categoryId, manualProductIds) {
                AppNavigator.push(
                  context,
                  BlocProvider(
                    create: (_) => ProductCubit(),
                    child: ProductScreen(
                      title: title.isNotEmpty
                          ? title
                          : context.translate(LanguageLabelKeys.products),
                      categoryId: categoryId,
                      dataSource: dataSource,
                      manualProductIds: manualProductIds,
                    ),
                  ),
                );
              },
            ),
          ),
          // The safe-area inset is only needed when the floating cart bar sits
          // above the bottom nav — without it the bar would cover the last row.
          BlocBuilder<CartCubit, CartState>(
            buildWhen: (prev, curr) =>
                (prev.totalItems > 0) != (curr.totalItems > 0),
            builder: (context, cartState) => SizedBox(
              height:
                  ThemeConstants.bottomBarHeight +
                  (cartState.totalItems > 0
                      ? context.bottomSafePadding
                      : context.bottomSafePadding / 2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = SettingsHiveBox.instance.hasLocation;

    if (!hasLocation) {
      return BlocListener<NavCubit, NavState>(
        listenWhen: (prev, curr) =>
            curr.currentIndex == 0 && prev.currentIndex != 0,
        listener: (context, state) {
          if (!SettingsHiveBox.instance.hasLocation && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openLocationSheet();
            });
          }
        },
        child: LocationRequiredView(
          onSetLocation: _openLocationSheet,
          onSearchManually: _openLocationSearch,
          onLocationConfirmed: _onLocationConfirmed,
        ),
      );
    }

    final g = _gradient(Theme.of(context));
    return BlocListener<HomeLayoutCubit, HomeLayoutState>(
      listener: (context, state) {
        if (state is HomeLayoutLoaded || state is HomeLayoutError) {
          context.read<CountrySettingsCubit>().loadCountrySettings(force: true);
        }
        if (state is HomeLayoutError) {
          // Drop stale sections so a retry's loading state doesn't flash
          // the previous (now invalid) layout before the error re-shows.
          setState(() => _layout = null);
        }
        if (state is HomeLayoutLoaded) {
          final data = state.homeLayout.data;
          if (SettingsHiveBox.instance.channel == AppConstants.quick) {
            SettingsHiveBox.instance.setStoreClosed(data?.storeClosed ?? 0);
          }
          final tabs = data?.categoryTabs ?? [];
          final old = _tabController;
          if (tabs.isNotEmpty) {
            final needNew = old == null || old.length != tabs.length;
            final newCtrl = needNew ? _makeTabController(tabs.length) : old;
            setState(() {
              _layoutMode = data?.availableModes ?? '';
              _homeType = HomeType.fromRaw(data?.homeType);
              _layout = data?.layout;
              _timeToDeliver = data?.timeToDeliver;
              _distance = data?.distance;
              _channelLabelQuick = data?.quickButtonLabel;
              _channelLabelEcommerce = data?.ecommerceButtonLabel;
              _searchSuggestions = data?.searchSuggestions;
              _categoryTabs = tabs;
              _tabController = newCtrl;
            });
            if (needNew) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => old?.dispose(),
              );
              // If first tab is a specific category (not "All"/null id), reload content filtered by it
              final firstTabId = tabs.isNotEmpty ? tabs.first.id : null;
              if (firstTabId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<HomeLayoutCubit>().loadHomeLayout(
                      categoryId: firstTabId,
                    );
                  }
                });
              }
            }
          } else {
            setState(() {
              _layoutMode = data?.availableModes ?? '';
              _homeType = HomeType.fromRaw(data?.homeType);
              _layout = data?.layout;
              _timeToDeliver = data?.timeToDeliver;
              _distance = data?.distance;
              _channelLabelQuick = data?.quickButtonLabel;
              _channelLabelEcommerce = data?.ecommerceButtonLabel;
              _searchSuggestions = data?.searchSuggestions;
              _tabController = null;
              _categoryTabs = [];
            });
            WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
          }
        }
      },
      child: AppScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        applyBottomInset: false,
        body: Stack(
          children: [
            RefreshIndicator(
              color: _currentHeaderColor(Theme.of(context)),
              onRefresh: () async {
                final idx = _tabController?.index ?? 0;
                final cartCubit = context.read<CartCubit>();
                context
                    .read<HomeLayoutCubit>()
                    .loadHomeLayout(categoryId: _categoryIdAt(idx))
                    .then((onValue) {
                      if (AuthHiveBox.instance.isLoggedIn) {
                        cartCubit.loadFromApi();
                      }
                    });
                await context.read<HomeLayoutCubit>().stream.firstWhere(
                  (s) => s is! HomeLayoutLoading,
                );
              },
              child: _buildScrollView(context, g),
            ),
            Positioned(
              top: _headerMinExtent(context) + ThemeConstants.paddingS,
              left: 0,
              right: 0,
              child: Center(
                child: _BackToTopButton(
                  visibleListenable: _isScrolled,
                  onTap: () {
                    if (!_scrollController.hasClients) return;
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollView(BuildContext context, List<Color> g) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: HomeAppBarDelegate(
            gradient: g,
            categoryTabs: _categoryTabs,
            tabController: _tabController,
            selectedMode: _selectedMode,
            onModeChanged: (i) async {
              if (i == _selectedMode) return;
              final old = _tabController;
              setState(() {
                _selectedMode = i;
                _categoryTabs = [];
                _tabController = null;
                // Channel switch loads a different catalog entirely —
                // clear the old layout so the skeleton shows instead
                // of the previous channel's stale sections.
                _layout = null;
              });
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => old?.dispose(),
              );
              final cartActionCubit = context.read<CartActionCubit>();
              final cartCubit = context.read<CartCubit>();
              final homeLayoutCubit = context.read<HomeLayoutCubit>();
              // Drain any debounced add/remove syncs under the OLD
              // channel before switching — otherwise a pending request
              // fires later with the NEW channel header against a
              // product from the old catalog ("item not found").
              await cartActionCubit.flushAllPending();
              if (!mounted) return;
              final ch = i == 1 ? AppConstants.ecommerce : AppConstants.quick;
              SettingsHiveBox.instance.setChannel(ch);
              if (AuthHiveBox.instance.isLoggedIn) {
                cartCubit.resetForChannelSwitch();
                homeLayoutCubit.loadHomeLayout().then((_) {
                  cartCubit.loadFromApi();
                });
              } else {
                cartCubit.switchChannel(ch);
                homeLayoutCubit.loadHomeLayout();
              }
            },
            onCategoryTabTap: (i) {
              if (_isScrolled.value && _scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              // Fires immediately on tap — waiting for the tab
              // indicator animation (controller listener) to settle
              // added a visible ~300ms delay before the skeleton
              // showed.
              setState(() {
                _layout = null;
              });
              context.read<HomeLayoutCubit>().loadHomeLayout(
                categoryId: _categoryIdAt(i),
              );
            },
            topPadding: context.topSafePadding,
            screenHeight: context.screenHeight,
            textScaleFactor: MediaQuery.textScalerOf(context).scale(1.0),
            locationLabel: _locationLabel,
            locationAddress: _locationAddress,
            onLocationTap: _openLocationSheet,
            layoutMode: _layoutMode,
            homeType: _homeType,
            layout: _layout,
            timeToDeliver: _timeToDeliver,
            distance: _distance,
            channelLabelQuick: _channelLabelQuick,
            channelLabelEcommerce: _channelLabelEcommerce,
            searchSuggestions: _searchSuggestions,
            selectedTab: (() {
              final idx = _tabController?.index ?? 0;
              return (_categoryTabs.isNotEmpty && idx < _categoryTabs.length)
                  ? _categoryTabs[idx]
                  : null;
            })(),
          ),
        ),
        BlocBuilder<HomeLayoutCubit, HomeLayoutState>(
          builder: (context, layoutState) {
            final sectionsEmpty =
                layoutState is HomeLayoutLoaded &&
                (layoutState.homeLayout.data?.layout?.sections ?? []).isEmpty;
            if (SettingsHiveBox.instance.isStoreClosedQuick && !sectionsEmpty) {
              return const SliverToBoxAdapter(child: StoreClosedBanner());
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
        BlocBuilder<HomeLayoutCubit, HomeLayoutState>(
          builder: (context, layoutState) {
            if (layoutState is HomeLayoutLoading) {
              final cachedSections = _layout?.sections ?? [];
              // A tab/category switch re-triggers loading — if we
              // already have a rendered layout, keep it on screen
              // instead of blanking out while the new one arrives.
              if (cachedSections.isNotEmpty) {
                return _buildSections(context, cachedSections);
              }
              return const SliverToBoxAdapter(child: HomeSkeletonLoader());
            }
            if (layoutState is HomeLayoutError) {
              return SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: context.screenHeight * 0.6,
                  ),
                  child: Center(
                    child: EmptyStateWidget(
                      imagePath: AssetsConstants.noSearchFound,
                      title: layoutState.message,
                      subtitle: context.translate(
                        LanguageLabelKeys.pullToRefresh,
                      ),
                      onRetry: () {
                        final idx = _tabController?.index ?? 0;
                        context.read<HomeLayoutCubit>().loadHomeLayout(
                          categoryId: _categoryIdAt(idx),
                        );
                      },
                    ),
                  ),
                ),
              );
            }
            if (layoutState is HomeLayoutLoaded) {
              final sections =
                  layoutState.homeLayout.data?.layout?.sections ?? [];
              if (sections.isEmpty) {
                return SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: context.screenHeight * 0.6,
                    ),
                    child: Center(
                      child: EmptyStateWidget(
                        imagePath: AssetsConstants.noSearchFound,
                        title: context.translate(
                          LanguageLabelKeys.noContentAvailable,
                        ),
                        subtitle: context.translate(
                          LanguageLabelKeys.contentCurrentlyUnavailable,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return _buildSections(context, sections);
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  final ValueListenable<bool> visibleListenable;
  final VoidCallback onTap;

  const _BackToTopButton({
    required this.visibleListenable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visibleListenable,
      builder: (context, visible, _) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          offset: visible ? Offset.zero : const Offset(0, -1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: visible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !visible,
              child: Material(
                color: context.cs.inverseSurface.withValues(alpha: 0.85),
                shape: const StadiumBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        AppSvgIcon(
                          AssetsConstants.arrowUpAndroidIcon,
                          color: context.cs.onInverseSurface,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        AppText(
                          context.translate(LanguageLabelKeys.backToTop),
                          style: context.tt.labelMedium?.copyWith(
                            color: context.cs.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
