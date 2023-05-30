import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NumberPicker extends StatefulWidget {
  final int? value;
  final Function? onChange;

  const NumberPicker({Key? key, this.value, this.onChange}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  int value = 0;

  @override
  initState() {
    super.initState();
    value = widget.value!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 20.0,
          splashRadius: 15.0,
          color: Colors.black38,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            FontAwesomeIcons.minus,
          ),
          onPressed: () => {
            if (value > 0)
              {
                setState(() {
                  value--;
                  widget.onChange!(value);
                })
              }
          },
        ),
        SizedBox(
          width: 45.0,
          child: Align(
            child: Text(value.toString(),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
          iconSize: 20.0,
          splashRadius: 15.0,
          color: Colors.black38,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            FontAwesomeIcons.plus,
          ),
          onPressed: () => {
            setState(() {
              value++;
              widget.onChange!(value);
            })
          },
        ),
      ],
    );
  }
}
