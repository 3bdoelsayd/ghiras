import 'dart:convert';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/linearicons_free_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../../core/constants/app_colors.dart';
import '../../core/helpers/hive_helper.dart';
import '../../features/quran/logic/player_bar_bloc/player_bar_bloc.dart';
import '../../features/quran/logic/player_bloc/player_bloc_bloc.dart';
import 'package:ghiras/main.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  @override
  void initState() {
    addFavorites();
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (isMinimized) {
      return false;
    } else {
      playerbarBloc.add(MinimizeBarEvent());
      isMinimized = true;
    }
    return true;
  }

  List favoriteSurahList = [];
  addFavorites() {
    favoriteSurahList = json.decode(getValue("favoriteSurahList") ?? "[]");
    setState(() {});
  }

  final appDir = Directory("/storage/emulated/0/Download/skoon/");
  bool isPlaylistShown = false;
  bool isMinimized = true;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Directionality(
        textDirection: m.TextDirection.ltr,
        child: BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
          bloc: playerPageBloc,
          builder: (context, state) {
            if (state is PlayerBlocPlaying) {
              return BlocBuilder<PlayerBarBloc, PlayerBarState>(
                bloc: playerbarBloc,
                builder: (context, statee) {
                  if (statee is PlayerBarHidden) {
                    return Positioned(
                        bottom: 100.h, // Adjusted to be above bottom nav
                        right: 25.w,
                        child: FadeInRight(
                          child: FadeInUp(
                            child: StreamBuilder<PlayerState>(
                                stream: state.audioPlayer.playerStateStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Opacity(
                                      opacity: .8,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: SpinPerfect(
                                          infinite: true,
                                          duration: const Duration(seconds: 7),
                                          animate: snapshot.data!.playing,
                                          child: GestureDetector(
                                            onTap: () {
                                              playerbarBloc.add(ShowBarEvent());
                                            },
                                            child: Container(
                                              height: 55.h,
                                              width: 55.w,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 10,
                                                  )
                                                ],
                                              ),
                                              child: const Center(
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.transparent,
                                                  backgroundImage: AssetImage("assets/images/iconlauncher.png"),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox();
                                  }
                                }),
                          ),
                        ));
                  } else if (statee is PlayerBarVisible) {
                    isMinimized = statee.height <= 60;
                    
                    return Positioned(
                      bottom: 0,
                      child: FadeInUp(
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onTap: () {
                              if (isMinimized) {
                                playerbarBloc.add(ExtendBarEvent());
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: isMinimized
                                  ? 60.h + 80 // Plus bottom nav height if needed, or stick to bottom
                                  : MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  color: isMinimized
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: isMinimized
                                      ? const BorderRadius.only(
                                          topLeft: Radius.circular(13),
                                          topRight: Radius.circular(13))
                                      : BorderRadius.zero),
                              child: isMinimized
                                  ? _buildMinimizedBar(state)
                                  : _buildMaximizedBar(state, context),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildMinimizedBar(PlayerBlocPlaying state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<PlayerState>(
              stream: state.audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SpinPerfect(
                    infinite: true,
                    duration: const Duration(seconds: 7),
                    animate: snapshot.data!.playing,
                    child: Container(
                      height: 45.h,
                      width: 45.w,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.darkPrimary),
                      child: const Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage("assets/images/iconlauncher.png"),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              }),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: StreamBuilder<SequenceState?>(
                  stream: state.audioPlayer.sequenceStateStream,
                  builder: (context, snapshot) {
                    final sequenceState = snapshot.data;
                    if (sequenceState?.sequence.isEmpty ?? true) {
                      return const SizedBox();
                    }
                    final metadata = sequenceState!.currentSource!.tag as MediaItem;
                    return Text(
                        "${metadata.title} - ${state.reciter.name}",
                        textAlign: TextAlign.center,
                        textDirection: m.TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontFamily: 'Cairo',
                        ));
                  }),
            ),
          ),
          Row(
            children: [
              StreamBuilder<PlayerState>(
                  stream: state.audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return IconButton(
                        onPressed: () {
                          snapshot.data!.playing ? state.audioPlayer.pause() : state.audioPlayer.play();
                        },
                        icon: Icon(
                          snapshot.data!.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      );
                    }
                    return const SizedBox();
                  }),
              IconButton(
                onPressed: () => playerbarBloc.add(HideBarEvent()),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaximizedBar(PlayerBlocPlaying state, BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill,
              opacity: .1,
              image: AssetImage("assets/images/framee.png"))),
      child: Column(
        children: [
          SizedBox(height: 50.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => playerbarBloc.add(MinimizeBarEvent()),
                icon: Icon(LineariconsFree.chevron_down, size: 25.sp, color: AppColors.primary),
              ),
              const Text(
                'الآن يتم التشغيل',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isPlaylistShown = !isPlaylistShown;
                  });
                },
                icon: Icon(Icons.playlist_play_rounded, size: 30.sp, color: AppColors.primary),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<SequenceState?>(
              stream: state.audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                final sequenceState = snapshot.data;
                if (sequenceState?.sequence.isEmpty ?? true) return const SizedBox();
                final metadata = sequenceState!.currentSource!.tag as MediaItem;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(metadata.title,
                        style: TextStyle(color: AppColors.textDark, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    Text(state.reciter.name,
                        style: TextStyle(color: AppColors.textGrey, fontSize: 16.sp, fontFamily: 'Cairo')),
                    SizedBox(height: 40.h),
                    Center(
                      child: Container(
                        width: 220.w,
                        height: 220.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          backgroundImage: AssetImage("assets/images/iconlauncher.png"),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ControlButtons(state.audioPlayer),
          SizedBox(height: 20.h),
          _buildProgressBar(state),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PlayerBlocPlaying state) {
    return StreamBuilder<Duration>(
      stream: state.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = state.audioPlayer.duration ?? Duration.zero;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Slider(
                value: position.inSeconds.toDouble(),
                max: total.inSeconds.toDouble() > 0 ? total.inSeconds.toDouble() : 1.0,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withOpacity(0.2),
                onChanged: (value) {
                  state.audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDuration(position), style: const TextStyle(color: AppColors.textGrey)),
                    Text(formatDuration(total), style: const TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;
  const ControlButtons(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, size: 35.sp, color: AppColors.primary),
          onPressed: player.hasPrevious ? player.seekToPrevious : null,
        ),
        SizedBox(width: 20.w),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final playing = playerState?.playing ?? false;
            final processingState = playerState?.processingState;
            
            if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (!playing) {
              return IconButton(
                icon: Icon(Icons.play_circle_fill_rounded, size: 70.sp, color: AppColors.primary),
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: Icon(Icons.pause_circle_filled_rounded, size: 70.sp, color: AppColors.primary),
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: Icon(Icons.replay_circle_filled_rounded, size: 70.sp, color: AppColors.primary),
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        SizedBox(width: 20.w),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, size: 35.sp, color: AppColors.primary),
          onPressed: player.hasNext ? player.seekToNext : null,
        ),
      ],
    );
  }
}

String formatDuration(Duration duration) {
  int minutes = duration.inMinutes;
  int seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
