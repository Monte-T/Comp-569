import 'package:flutter/material.dart';

class MyAuthButton extends StatelessWidget {
  final Function()? onTap;
  final String myButtonText;

  const MyAuthButton({super.key, required this.onTap, required this.myButtonText});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25),
        margin: EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),

        child: Center(
          child: Text(
            myButtonText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
