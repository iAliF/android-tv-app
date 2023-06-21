import 'package:flutter/material.dart';
import 'package:mawaqit/src/helpers/RelativeSizes.dart';
import 'package:mawaqit/src/helpers/StringUtils.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/themes/UIShadows.dart';
import 'package:mawaqit/src/widgets/time_widget.dart';
import 'package:provider/provider.dart';

class MiniHorizontalSalahItem extends StatelessWidget {
  const MiniHorizontalSalahItem({
    Key? key,
    required this.title,
    required this.time,
    this.active = false,
  }) : super(key: key);

  /// used to show salah name
  final String title;

  /// used to show salah time
  final String time;

  final bool active;

  @override
  Widget build(BuildContext context) {
    double bigFont = 6.0.vw;
    double smallFont = 3.6.vw;

    final mosqueProvider = context.watch<MosqueManager>();
    final mosqueConfig = mosqueProvider.mosqueConfig;

    final is24period = mosqueConfig?.timeDisplayFormat != "12";
    final isIqamaMoreImportant = mosqueConfig!.iqamaMoreImportant ?? false;

    return Container(
      margin: EdgeInsets.all(1.vw),
      padding: EdgeInsets.all(1.vw),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.vw),
        color: active ? mosqueProvider.getColorTheme().withOpacity(.5) : Colors.black.withOpacity(.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 4.vwr,
              shadows: kHomeTextShadow,
              color: Colors.white,
              fontFamily: StringManager.getFontFamilyByString(title ?? ""),
            ),
          ),
          SizedBox(width: 3.vw),
          TimeWidget.fromString(
            show24hFormat: is24period,
            time: time,
            style: TextStyle(
              fontSize: isIqamaMoreImportant ? smallFont : bigFont,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
