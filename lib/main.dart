import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_remote_data_source.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/verticals/data/verticals_repository.dart';
import 'features/verticals/bloc/verticals_bloc.dart';
import 'features/verticals/presentation/verticals_screen.dart';
import 'features/categories/data/categories_repository.dart';
import 'features/categories/bloc/categories_bloc.dart';
import 'features/categories/presentation/categories_screen.dart';
import 'features/products/data/products_repository.dart';
import 'features/products/bloc/products_bloc.dart';
import 'features/products/presentation/products_screen.dart';
import 'features/orders/data/orders_repository.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/stats/data/stats_repository.dart';
import 'features/stats/bloc/stats_bloc.dart';
import 'features/stats/presentation/stats_screen.dart';
import 'features/users/data/users_repository.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/users/presentation/users_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const TradexaAdminApp());
}

class TradexaAdminApp extends StatelessWidget {
  const TradexaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = SupabaseConfig.client;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(AuthRepository(SupabaseAuthRemoteDataSource(client))),
        ),
        BlocProvider(create: (_) => VerticalsBloc(VerticalsRepository(client))),
        BlocProvider(create: (_) => CategoriesBloc(CategoriesRepository(client))),
        BlocProvider(
          create: (_) => ProductsBloc(
            ProductsRepository(client),
            CategoriesRepository(client),
          ),
        ),
        BlocProvider(create: (_) => OrdersBloc(OrdersRepository(client))),
        BlocProvider(create: (_) => UsersBloc(UsersRepository(client))),
        BlocProvider(create: (_) => StatsBloc(StatsRepository(client))),
      ],
      child: MaterialApp(
        title: 'Tradexa Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Directionality(textDirection: TextDirection.rtl, child: child!);
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/verticals': (context) => const VerticalsScreen(),
          '/products': (context) => const ProductsScreen(),
          '/categories': (context) => const CategoriesScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/users': (context) => const UsersScreen(),
          '/stats': (context) => const StatsScreen(),
        },
      ),
    );
  }
}
