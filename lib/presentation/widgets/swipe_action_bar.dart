import 'package:flutter/material.dart';

class SwipeActionBar extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  const SwipeActionBar({
    super.key,
    required this.onDislike,
    required this.onSuperLike,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(icon: Icons.close, color: Colors.red, onTap: onDislike),
        _RoundAction(
            icon: Icons.star,
            color: Colors.blue,
            size: 50,
            iconSize: 25,
            onTap: onSuperLike),
        _RoundAction(icon: Icons.favorite, color: Colors.green, onTap: onLike),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 60,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
