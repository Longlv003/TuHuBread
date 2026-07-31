import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/models/user.model.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/cart/cart_cubit.dart';
import '../blocs/home/home_cubit.dart';
import '../blocs/notification/notification_cubit.dart';
import '../blocs/notification/notification_state.dart';
import '../blocs/order/order_cubit.dart';
import '../di.dart';
import '../routes/routes.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/customer_header.dart';
import 'notifications_page.dart';
import 'tabs/cart_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (getx.Get.arguments is int) {
      _currentIndex = getx.Get.arguments as int;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartCubit>().loadCart();
        getIt<NotificationCubit>().refreshUnreadCount();
      }
    });
  }

  Future<void> _onBellPressed() async {
    await getx.Get.to(() => const NotificationsPage());
    // Đề phòng có thay đổi từ màn thông báo mà state chưa kịp đồng bộ.
    getIt<NotificationCubit>().refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          getx.Get.offAllNamed(Routes.loginPage);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final user = state.user;

            // List of views for each tab
            final List<Widget> tabViews = [
              HomeTab(user: user),
              CartTab(user: user),
              HistoryTab(user: user),
              ProfileTab(user: user),
            ];

            return MultiBlocProvider(
              providers: [
                BlocProvider<HomeCubit>(
                  create: (_) => getIt<HomeCubit>()..loadHomeData(),
                ),
                BlocProvider<OrderCubit>(
                  create: (_) => getIt<OrderCubit>()..loadOrders(),
                ),
              ],
              child: Builder(
                builder: (context) {
                  return Scaffold(
                    backgroundColor: const Color(0xFFFDFBF7),
                    body: SafeArea(
                      child: Column(
                        children: [
                          // Extracted Reusable Header Customer — ẩn ở tab Giỏ hàng
                          // để nhường thêm diện tích cho danh sách sản phẩm.
                          CustomerHeader(
                            user: user,
                            titleWidget: _buildHeaderWidgetForTab(user, l10n),
                            unreadNotifications: context.select<NotificationCubit, int>(
                              (cubit) => cubit.state is NotificationLoaded
                                  ? (cubit.state as NotificationLoaded).unreadCount
                                  : 0,
                            ),
                            onNotificationTap: _onBellPressed,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1EAE1)),
                          // Active Tab View Content — IndexedStack giữ nguyên state của
                          // từng tab (không rebuild/dispose khi chuyển tab) để tránh giật/lag
                          Expanded(
                            child: IndexedStack(
                              index: _currentIndex,
                              children: tabViews,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Extracted Reusable Bottom Navigation Bar
                    bottomNavigationBar: CustomerBottomNav(
                      currentIndex: _currentIndex,
                      cartItemCount: context.select<CartCubit, int>(
                        (cubit) => cubit.state.totalQuantity,
                      ),
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE67E22),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderWidgetForTab(UserModel user, AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeWelcome,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 2),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        );
      case 1:
        return Text(
          l10n.cartTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        );
      case 2:
        return Text(
          l10n.historyTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        );
      case 3:
        return Text(
          l10n.profileTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
