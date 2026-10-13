// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:next_level/2%20General/app_colors.dart';
// import 'package:provider/provider.dart';
// import 'package:next_level/6%20Provider/profile_view_model.dart';

// // This chart shows weekly progress for each skill
// // Displays how much time spent on each skill per day of the week
// // Data is grouped by skills and shows multiple lines for top skills

// class WeeklyProgressChart extends StatefulWidget {
//   const WeeklyProgressChart({super.key});

//   @override
//   State<StatefulWidget> createState() => WeeklyProgressChartState();
// }

// class WeeklyProgressChartState extends State<WeeklyProgressChart> {
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 250,
//       child: Stack(
//         children: <Widget>[
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: <Widget>[
//               Text(
//                 "Yeteneklere Göre Haftalık İlerleme",
//                 style: TextStyle(
//                   color: AppColors.main,
//                   fontSize: 25,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.only(right: 16, left: 6),
//                   child: _LineChart(),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LineChart extends StatelessWidget {
//   const _LineChart();

//   @override
//   Widget build(BuildContext context) {
//     final viewModel = context.read<ProfileViewModel>();
//     final skillDurations = viewModel.getSkillDurations();
//     final topSkillsList = viewModel.getTopSkills(context, skillDurations);

//     List<LineChartBarData> dataList = [];
//     // Calculate max value from all data points
//     double maxHours = 0;

//     for (var skill in topSkillsList) {
//       var skillData = skillDurations[skill.id]!;

//       dataList.add(LineChartBarData(
//         isCurved: true,
//         color: skill.color,
//         barWidth: 3,
//         isStrokeCapRound: true,
//         dotData: const FlDotData(show: false),
//         belowBarData: BarAreaData(show: false),
//         spots: List.generate(7, (index) {
//           // Calculate dates from Monday to Sunday
//           DateTime now = DateTime.now();
//           // Find the most recent Monday
//           DateTime monday = now.subtract(Duration(days: now.weekday - 1));
//           // Add index days to get the current day
//           DateTime date = monday.add(Duration(days: index));
//           date = DateTime(date.year, date.month, date.day);

//           double hours = (skillData[date]?.inHours.toDouble() ?? 0) + (skillData[date]?.inMinutes.remainder(60).toDouble() ?? 0) / 60;
//           if (hours > maxHours) {
//             maxHours = hours;
//           }
//           return FlSpot(
//             index.toDouble(),
//             hours,
//           );
//         }),
//       ));
//     }

//     // Round up to next multiple of 5 for better readability
//     maxHours = ((maxHours + 4.99) ~/ 5) * 5.0;
//     maxHours = maxHours < 5 ? 5 : maxHours;

//     Widget bottomTitleWidgets(
//       double value,
//       TitleMeta meta,
//     ) {
//       late List<String> days;

//       if (context.locale == const Locale('en', 'US')) {
//         days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//       } else {
//         days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
//       }

//       return SideTitleWidget(
//         axisSide: meta.axisSide,
//         space: 10,
//         child: Text(
//           days[value.toInt()],
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       );
//     }

//     Widget leftTitleWidgets(double value, TitleMeta meta) {
//       // Show values at 0%, 25%, 50%, 75%, and 100% of maxHours
//       double currentValue = (maxHours * value) / 4;

//       String hourText = context.locale == const Locale('en', 'US') ? '${currentValue.toStringAsFixed(0)}h' : '${currentValue.toStringAsFixed(0)}s';

//       return Text(hourText,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//           textAlign: TextAlign.center);
//     }

//     return LineChart(
//       LineChartData(
//         lineTouchData: LineTouchData(
//           handleBuiltInTouches: true,
//           touchTooltipData: LineTouchTooltipData(
//             getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
//           ),
//         ),
//         gridData: const FlGridData(show: false),
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 32,
//               interval: 1,
//               getTitlesWidget: bottomTitleWidgets,
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               getTitlesWidget: leftTitleWidgets,
//               showTitles: true,
//               reservedSize: 40,
//               interval: maxHours / 4,
//             ),
//           ),
//           rightTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           topTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border(
//             bottom: BorderSide(color: AppColors.main),
//             left: BorderSide(color: AppColors.main),
//           ),
//         ),
//         lineBarsData: dataList,
//         minX: 0,
//         maxX: 6,
//         maxY: dataList.isEmpty ? 5 : maxHours,
//         minY: 0,
//       ),
//     );
//   }
// }
