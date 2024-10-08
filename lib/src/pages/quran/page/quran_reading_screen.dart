import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mawaqit/i18n/l10n.dart';
import 'package:mawaqit/src/pages/quran/page/reciter_selection_screen.dart';
import 'package:mawaqit/src/pages/quran/widget/switch_button.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_notifier.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_state.dart';
import 'package:mawaqit/src/state_management/quran/quran/quran_notifier.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_notifer.dart';

import 'package:mawaqit/src/pages/quran/widget/download_quran_popup.dart';

import 'package:sizer/sizer.dart';

import 'package:mawaqit/src/state_management/quran/quran/quran_state.dart';

import 'package:mawaqit/src/pages/quran/widget/reading/quran_reading_page_selector.dart';

class QuranReadingScreen extends ConsumerStatefulWidget {
  const QuranReadingScreen({super.key});

  @override
  ConsumerState createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends ConsumerState<QuranReadingScreen> {
  int quranIndex = 0;
  late FocusNode _backButtonFocusNode;
  late FocusNode _rightSkipButtonFocusNode;
  late FocusNode _leftSkipButtonFocusNode;
  late FocusNode _listeningModeFocusNode;
  late FocusNode _choosePageFocusNode;
  final ScrollController _gridScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _backButtonFocusNode = FocusNode(debugLabel: 'node_backButton');
    _listeningModeFocusNode = FocusNode(debugLabel: 'node_listeningMode');
    _rightSkipButtonFocusNode = FocusNode(debugLabel: 'node_rightSkip');
    _leftSkipButtonFocusNode = FocusNode(debugLabel: 'node_leftSkip');
    _choosePageFocusNode = FocusNode(debugLabel: 'node_choosePage');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ref.read(downloadQuranPopUpProvider.notifier).showDownloadQuranAlertDialog(context);
      ref.read(downloadQuranPopUpProvider.notifier).showDownloadQuranAlertDialog(context);
      ref.read(quranReadingNotifierProvider);
      // await showDownloadQuranAlertDialog(context, ref, _scaffoldKey);
    });
  }

  @override
  void dispose() {
    // _listeningModeFocusNode.dispose();
    // _rightSkipButtonFocusNode.dispose();
    // _gridScrollController.dispose();
    // _leftSkipButtonFocusNode.dispose();
    // _backButtonFocusNode.dispose();
    // _choosePageFocusNode.dispose();
    super.dispose();
  }

  FloatingActionButtonLocation _getFloatingActionButtonLocation(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    switch (textDirection) {
      case TextDirection.ltr:
        return FloatingActionButtonLocation.endFloat;
      case TextDirection.rtl:
        return FloatingActionButtonLocation.startFloat;
      default:
        return FloatingActionButtonLocation.endFloat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quranReadingState = ref.watch(quranReadingNotifierProvider);

    ref.listen(downloadQuranNotifierProvider, (previous, next) {
      if (!next.hasValue || next.value is Success) {
        log('quran: QuranReadingScreen: Downloaded quran');
        ref.invalidate(quranReadingNotifierProvider);
      }
    });

    return WillPopScope(
      onWillPop: () async {
        ref.read(downloadQuranPopUpProvider.notifier).dispose();
        return true;
      },
      child: KeyboardListener(
        onKeyEvent: _handleKeyEvent,
        focusNode: FocusNode(debugLabel: 'node_quranReadingScreen'),
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          floatingActionButtonLocation: _getFloatingActionButtonLocation(context),
          floatingActionButton: SizedBox(
            width: 30.sp, // Set the desired width
            height: 30.sp, //
            child: FloatingActionButton(
              focusNode: _listeningModeFocusNode,
              backgroundColor: Colors.black.withOpacity(.3),
              child: Icon(
                Icons.headset,
                color: Colors.white,
                size: 15.sp,
              ),
              onPressed: () async {
                ref.read(quranNotifierProvider.notifier).selectModel(QuranMode.listening);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReciterSelectionScreen.withoutSurahName(),
                  ),
                );
              },
            ),
          ),
          body: quranReadingState.when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, s) {
              final errorLocalized = S.of(context).error;
              return Center(child: Text('$errorLocalized: $error'));
            },
            data: (quranReadingState) {
              return Stack(
                children: [
                  PageView.builder(
                    reverse: Directionality.of(context) == TextDirection.ltr ? true : false,
                    controller: quranReadingState.pageController,
                    onPageChanged: (index) {
                      final actualPage = index * 2;
                      if (actualPage != quranReadingState.currentPage) {
                        ref.read(quranReadingNotifierProvider.notifier).updatePage(actualPage);
                      }
                    },
                    itemCount: (quranReadingState.totalPages / 2).ceil(),
                    itemBuilder: (context, index) {
                      final leftPageIndex = index * 2;
                      final rightPageIndex = leftPageIndex + 1;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final pageWidth = constraints.maxWidth / 2;
                          final pageHeight = constraints.maxHeight;
                          final bottomPadding = pageHeight * 0.05; // 5% of screen height for bottom padding

                          return Stack(
                            children: [
                              // Right Page (now on the left)
                              if (rightPageIndex < quranReadingState.svgs.length)
                                Positioned(
                                  left: 12.w,
                                  top: 0,
                                  bottom: bottomPadding,
                                  width: pageWidth * 0.9,
                                  child: _buildSvgPicture(
                                    quranReadingState.svgs[rightPageIndex % quranReadingState.svgs.length],
                                  ),
                                ),
                              // Left Page (now on the right)
                              if (leftPageIndex < quranReadingState.svgs.length)
                                Positioned(
                                  right: 12.w,
                                  top: 0,
                                  bottom: bottomPadding,
                                  width: pageWidth * 0.9,
                                  child: _buildSvgPicture(
                                    quranReadingState.svgs[leftPageIndex % quranReadingState.svgs.length],
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: SwitchButton(
                      focusNode: _rightSkipButtonFocusNode,
                      opacity: 0.7,
                      iconSize: 14.sp,
                      icon: Directionality.of(context) == TextDirection.ltr
                          ? Icons.arrow_forward_ios
                          : Icons.arrow_back_ios,
                      onPressed: () => _scrollPageList(ScrollDirection.forward),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: SwitchButton(
                      focusNode: _leftSkipButtonFocusNode,
                      opacity: 0.7,
                      iconSize: 14.sp,
                      icon: Directionality.of(context) != TextDirection.ltr
                          ? Icons.arrow_forward_ios
                          : Icons.arrow_back_ios,
                      onPressed: () => _scrollPageList(ScrollDirection.reverse),
                    ),
                  ),
                  // Page Number
                  Positioned(
                    left: 15.w,
                    right: 15.w,
                    bottom: 1.h,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          autofocus: true,
                          focusNode: _choosePageFocusNode,
                          onTap: () => _showPageSelector(
                            context,
                            quranReadingState.totalPages,
                            quranReadingState.currentPage,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              S.of(context).quranReadingPage(
                                    quranReadingState.currentPage + 1,
                                    quranReadingState.currentPage + 2,
                                    quranReadingState.totalPages,
                                  ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // back button
                  Positioned(
                    left: Directionality.of(context) == TextDirection.ltr ? 10 : null,
                    right: Directionality.of(context) == TextDirection.rtl ? 10 : null,
                    child: SwitchButton(
                      focusNode: _backButtonFocusNode,
                      opacity: 0.7,
                      iconSize: 17.sp,
                      splashFactorSize: 0.9,
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        log('quran: QuranReadingScreen: back');
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _scrollPageList(ScrollDirection direction) {
    if (direction == ScrollDirection.forward) {
      ref.read(quranReadingNotifierProvider.notifier).previousPage();
    } else {
      ref.read(quranReadingNotifierProvider.notifier).nextPage();
    }
  }

  Widget _buildSvgPicture(SvgPicture svgPicture) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(32.0),
      child: SvgPicture(
        svgPicture.bytesLoader,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
      ),
    );
  }

  void _showPageSelector(BuildContext context, int totalPages, int currentPage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuranReadingPageSelector(
          currentPage: currentPage,
          scrollController: _gridScrollController,
          totalPages: totalPages,
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _rightSkipButtonFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _leftSkipButtonFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _backButtonFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (FocusScope.of(context).focusedChild == _listeningModeFocusNode) {
          _choosePageFocusNode.requestFocus();
        } else {
          _listeningModeFocusNode.requestFocus();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        if (FocusScope.of(context).focusedChild == _choosePageFocusNode) {}
      }
    }
  }
}
