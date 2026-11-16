import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/cart/cart_screen.dart';

class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemCount;
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      child: IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        tooltip: 'Keranjang',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
      ),
    );
  }
}
