import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:provider/provider.dart';

class FocusModeBypassSheet extends StatefulWidget {
  final HomeViewModel homeViewModel;
  const FocusModeBypassSheet({super.key, required this.homeViewModel});

  @override
  State<FocusModeBypassSheet> createState() => _FocusModeBypassSheetState();
}

class _FocusModeBypassSheetState extends State<FocusModeBypassSheet> {
  late bool _onlyRoutines;

  @override
  void initState() {
    super.initState();
    _onlyRoutines = widget.homeViewModel.focusModeOnlyRoutines;
  }

  @override
  Widget build(BuildContext context) {
    // Get the routines directly from TaskProvider
    final routines = context.watch<TaskProvider>().routineList;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.dirtyWhite),
        ),
      ),
      padding: const EdgeInsets.all(16),
      // Set a maximum height so it's scrollable if there are many routines
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Odak Modu Bypass",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: AppColors.text,
              ),
            ],
          ),

          // "Sadece Rutinler İçin" switch
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.main.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.2),
              ),
            ),
            child: SwitchListTile(
              title: Text(
                "Sadece Rutinler İçin",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              subtitle: Text(
                "Aktifken odak modu sadece rutinlere uygulanır, tek seferlik görevler etkilenmez.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
              ),
              value: _onlyRoutines,
              activeThumbColor: AppColors.main,
              contentPadding: EdgeInsets.zero,
              onChanged: (bool value) {
                setState(() {
                  _onlyRoutines = value;
                });
                widget.homeViewModel.toggleFocusModeOnlyRoutines();
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Bu listede işaretlenen rutinler yalnızca 'Odak Modu' filtresinden muaf tutulur. Diğer filtrelere uymuyorsa yine gizlenir.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
          ),

          if (routines.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  "Kayıtlı rutin bulunmuyor.",
                  style:
                      TextStyle(color: AppColors.text.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: routines.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppColors.dirtyWhite.withValues(alpha: 0.5),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  return SwitchListTile(
                    title: Text(
                      routine.title,
                      style: TextStyle(color: AppColors.text),
                    ),
                    subtitle: routine.description != null &&
                            routine.description!.isNotEmpty
                        ? Text(
                            routine.description!,
                            style: TextStyle(
                              color: AppColors.text.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    value: routine.isFocusModeBypassed,
                    activeThumbColor: AppColors.purple,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) async {
                      setState(() {
                        routine.isFocusModeBypassed = value;
                      });
                      // Save directly to Hive
                      await routine.save();
                      // Notify listeners in TaskProvider to trigger UI update
                      if (context.mounted) {
                        context.read<TaskProvider>().updateItems();
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
