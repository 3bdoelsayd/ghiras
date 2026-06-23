import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../features/quran/logic/player_bloc/player_bloc_bloc.dart';
import '../../features/quran/logic/player_bar_bloc/player_bar_bloc.dart';
import '../../core/helpers/hive_helper.dart';
import 'package:ghiras/main.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBarBloc, PlayerBarState>(
      builder: (context, barState) {
        if (barState is PlayerBarHidden || barState is PlayerBarClosed) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
          builder: (context, playerState) {
            if (playerState is! PlayerBlocPlaying) {
              return const SizedBox.shrink();
            }

            return StreamBuilder<SequenceState?>(
              stream: audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                final sequenceState = snapshot.data;
                if (sequenceState == null) return const SizedBox.shrink();

                final currentItem = sequenceState.currentSource?.tag;
                final title = currentItem?.title ?? "القرآن الكريم";
                final artist = currentItem?.artist ?? playerState.reciter.name;
                final photoUrl = getValue("${playerState.reciter.name} photo url");

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شريط التقدم في الأعلى
                    _buildProgressBar(),
                    
                    Padding(
                      padding: EdgeInsets.fromLTRB(10.w, 4.h, 4.w, 4.h),
                      child: Row(
                        children: [
                          // صورة القارئ
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                              image: photoUrl != null 
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            ),
                            child: photoUrl == null 
                              ? Icon(Icons.person_rounded, color: AppColors.primary, size: 20.sp)
                              : null,
                          ),
                          SizedBox(width: 10.w),
                          
                          // المعلومات
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  artist,
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 10.sp,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // أزرار التحكم
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audioPlayer.duration ?? Duration.zero;

        return ProgressBar(
          progress: position,
          total: duration,
          buffered: audioPlayer.bufferedPosition,
          onSeek: (duration) => audioPlayer.seek(duration),
          barHeight: 2.h,
          baseBarColor: Colors.transparent,
          progressBarColor: AppColors.primary,
          bufferedBarColor: Colors.transparent,
          thumbColor: AppColors.primary,
          thumbRadius: 0,
          timeLabelLocation: TimeLabelLocation.none,
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing;
        final processingState = playerState?.processingState;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // السورة السابقة (تكون على اليمين في العربي)
            _playerBtn(
              icon: Icons.skip_previous_rounded, 
              onTap: audioPlayer.hasPrevious ? () => audioPlayer.seekToPrevious() : null,
              size: 22,
            ),
            
            GestureDetector(
              onTap: () {
                if (playing == true) {
                  audioPlayer.pause();
                } else {
                  audioPlayer.play();
                }
              },
              child: Container(
                width: 32.w,
                height: 32.h,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering
                    ? Padding(
                        padding: EdgeInsets.all(8.r),
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Icon(
                        playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
              ),
            ),

            // السورة التالية (تكون على اليسار في العربي)
            _playerBtn(
              icon: Icons.skip_next_rounded,
              onTap: audioPlayer.hasNext ? () => audioPlayer.seekToNext() : null,
              size: 22,
            ),
            
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 16.sp),
              onPressed: () => context.read<PlayerBlocBloc>().add(ClosePlayerEvent()),
            ),
          ],
        );
      },
    );
  }

  Widget _playerBtn({required IconData icon, required VoidCallback? onTap, double size = 24}) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(icon, color: onTap == null ? Colors.grey.shade300 : AppColors.primary, size: size.sp),
      onPressed: onTap,
    );
  }
}
