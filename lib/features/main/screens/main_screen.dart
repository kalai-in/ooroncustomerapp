import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/commons/cubit/connectivity_cubit.dart';
import 'package:customer/commons/widgets/app_no_internet_widget.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/localization/cubit/language_cubit.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/category/cubit/category_cubit.dart';
import 'package:customer/features/category/screens/category_screen.dart';
import 'package:customer/features/favourite/cubit/favorite_cubit.dart';
import 'package:customer/features/favourite/screens/favourite_screen.dart';
import 'package:customer/features/home/cubits/home_layout_cubit.dart';
import 'package:customer/features/home/screens/home_screen.dart';
import 'package:customer/features/main/models/bottom_navigation.dart';
import 'package:customer/features/main/widgets/bottom_navigation.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/main/widgets/floating_cart_bar.dart';
import 'package:customer/features/profile/screens/profile_screen.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/nav_cubit.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _homeLayoutCubit = HomeLayoutCubit();
  final _categoryCubit = CategoryCubit();
  late final _screens = [
    BlocProvider.value(value: _homeLayoutCubit, child: const HomeScreen()),
    BlocProvider.value(value: _categoryCubit, child: const CategoryScreen()),
    const FavouriteScreen(),
    const ProfileScreen(),
  ];

  static List<BottomNavItem> _navItems(BuildContext context) => [
    BottomNavItem(
      label: context.translate(LanguageLabelKeys.home),
      activeIconPath: AssetsConstants.homeActiveIcon,
      inactiveIconPath: AssetsConstants.homeInActiveIcon,
    ),
    BottomNavItem(
      label: context.translate(LanguageLabelKeys.categories),
      activeIconPath: AssetsConstants.categoryActiveIcon,
      inactiveIconPath: AssetsConstants.categoryInActiveIcon,
    ),
    BottomNavItem(
      label: context.translate(LanguageLabelKeys.favourites),
      activeIconPath: AssetsConstants.favouriteActiveIcon,
      inactiveIconPath: AssetsConstants.favouriteInActiveIcon,
    ),
    BottomNavItem(
      label: context.translate(LanguageLabelKeys.profile),
      activeIconPath: AssetsConstants.profileActiveIcon,
      inactiveIconPath: AssetsConstants.profileInActiveIcon,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (AuthHiveBox.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CartCubit>().loadFromApi(),
      );
    }
  }

  @override
  void dispose() {
    _homeLayoutCubit.close();
    _categoryCubit.close();
    super.dispose();
  }

  void _reloadOnLanguageChange() {
    _homeLayoutCubit.loadHomeLayout();
    _categoryCubit.loadCategories();
    if (AuthHiveBox.instance.isLoggedIn) {
      context.read<FavoriteCubit>().loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The offline state is layered *over* the shell rather than replacing it:
    // rebuilding this subtree would recreate NavCubit (resetting the tab back
    // to Home) and tear down all four tab screens, losing their scroll and
    // pagination state every time the network blips.
    return BlocProvider(
      create: (_) => NavCubit(),
      child: BlocListener<LanguageCubit, LanguageState>(
        listenWhen: (previous, current) =>
            previous is LanguageLoaded &&
            current is LanguageLoaded &&
            previous.selectedId != current.selectedId,
        listener: (context, state) => _reloadOnLanguageChange(),
        child: BlocBuilder<NavCubit, NavState>(
          builder: (context, state) {
            return BlocBuilder<ConnectivityCubit, ConnectivityState>(
              builder: (context, connectivityState) {
                final isOffline = connectivityState is ConnectivityDisconnected;
                return PopScope(
                  canPop: state.currentIndex == 0,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    context.read<NavCubit>().changeTab(0);
                  },
                  child: AppScaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    applyBottomInset: false,
                    body: Stack(
                      children: [
                        IndexedStack(
                          index: state.currentIndex,
                          children: _screens,
                        ),
                        if (state.currentIndex != 3)
                          Positioned(
                            bottom:
                                ThemeConstants.bottomBarHeight +
                                context.bottomSafePadding,
                            left: 0,
                            right: 0,
                            child: FloatingCartBar(
                              onViewCart: () => AppNavigator.pushNamed(
                                context,
                                RouteNames.checkout,
                              ),
                            ),
                          ),
                        // Last child so it covers the tab content and the floating
                        // cart bar, while the bottom nav (outside the body) stays
                        // reachable.
                        if (isOffline)
                          const Positioned.fill(child: AppNoInternetView()),
                      ],
                    ),
                    bottomNavigationBar: BottomNavBar(
                      currentIndex: state.currentIndex,
                      onTap: context.read<NavCubit>().changeTab,
                      items: _navItems(context),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
