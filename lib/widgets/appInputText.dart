import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rider_frontend/styles.dart';

class AppInputText extends StatelessWidget {
  final Function onTapCallback;
  final String hintText;
  final Color hintColor;
  final IconData iconData;
  final IconData endIcon;
  final Function onSubmittedCallback;
  final TextEditingController controller;
  final List<TextInputFormatter> inputFormatters;
  final double width;
  final TextInputType keyboardType;
  final Function endIconOnTapCallback;
  final bool obscureText;
  final bool autoFocus;
  final FocusNode focusNode;
  final bool enabled;
  final double fontSize;
  final int maxLines;

  AppInputText({
    this.maxLines,
    this.enabled,
    this.hintText,
    this.hintColor,
    this.iconData,
    this.endIcon,
    this.onTapCallback,
    this.onSubmittedCallback,
    this.inputFormatters,
    this.controller,
    this.width,
    this.keyboardType,
    this.endIconOnTapCallback,
    this.obscureText,
    this.autoFocus,
    this.focusNode,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      height: 50,
      width: width,
      child: Row(
        children: [
          iconData != null
              ? Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(iconData),
                )
              : Container(),
          Expanded(
            child: TextField(
              onTap: onTapCallback,
              maxLines: maxLines,
              enabled: enabled,
              autofocus: autoFocus ?? false,
              focusNode: focusNode,
              inputFormatters: inputFormatters,
              onSubmitted: onSubmittedCallback,
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: fontSize ?? 18),
              obscureText: obscureText ?? false,
              decoration: InputDecoration(
                  hintText: this.hintText,
                  hintStyle: TextStyle(
                    fontSize: fontSize ?? 18,
                    color: hintColor ??
                        (onTapCallback != null
                            ? AppColor.secondaryPurple
                            : AppColor.disabled),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                  )),
            ),
          ),
          endIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: endIconOnTapCallback != null
                        ? endIconOnTapCallback
                        : () {},
                    child: Icon(
                      endIcon,
                      color: AppColor.disabled,
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
