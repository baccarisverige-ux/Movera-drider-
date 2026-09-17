import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/earning%20stats/earning_stats.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AnalyticsEarnings extends StatelessWidget {
  const AnalyticsEarnings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Earnings',
          color: AppColor.title,
          fontSize: 20,
          fontWeight: fwSemiBold,
        ),
        20.height,
        SizedBox(
          height: ResSize.h * 180,
          width: double.infinity,
          child: flchart(),
        ),
        14.height,
        CustomButton(
          centerContent: "View all stats",
          onPressed: () {
            Navigator.push(
              context,
              RightToLeftTransition(EarningStatsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget flchart() {
    final List<double> values = [62, 24, 48, 72, 10, 56, 64];
    final List<String> labels = [
      '10:00',
      '11:00',
      '11:45',
      '12:30',
      '12:59',
      '13:30',
      '14:30',
    ];

    // Define your custom left axis values
    final List<int> leftValues = [0, 20, 40, 60, 80];

    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        // Set the min and max Y values to match your left axis range
        minY: 0,
        maxY: 80,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 20, // This ensures values appear at 0, 20, 40, 60, 80
              getTitlesWidget: (value, meta) {
                // Only show titles for your specific left values
                if (leftValues.contains(value.toInt())) {
                  return TextWidget(
                    text: value.toInt().toString(),
                    color: const Color(0xFF606060),
                    fontSize: 11,
                    fontWeight: fwMedium,
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 32,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8 * ResSize.h),
                    child: TextWidget(
                      text: labels[value.toInt()],
                      color: const Color(0xFF606060),
                      fontSize: 11,
                      fontWeight: fwMedium,
                      // letterSpacing: 0.2,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 6 * ResSize.w,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: 20 * ResSize.w,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF12AF54), Color(0xFF12AF54)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 80,
                  color: const Color(0xFFF0EFEF),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
