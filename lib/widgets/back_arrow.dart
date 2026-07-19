import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackArrow extends StatelessWidget {
  final Color? color;

  const BackArrow({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        final path = GoRouterState.of(context).uri.toString();

        if (path == '/my-orders' || path == '/my-seller-orders') {
          context.go('/profile');
          return;
        }



        if (path == '/my-products' ||

            path == '/admin-dashboard' ||
            path == '/privacy-policy') {
          context.go('/profile');
          return;
        }

        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go('/home');
      },
    );
  }
}