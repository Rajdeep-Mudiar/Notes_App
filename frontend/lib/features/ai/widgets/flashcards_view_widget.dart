import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/ai/models/ai_model.dart';
import 'package:frontend/features/ai/providers/ai_provider.dart';
import 'package:frontend/features/ai/widgets/citation_chip_widget.dart';

class FlashcardsViewWidget extends ConsumerStatefulWidget {
  final FlashcardResponseModel deck;

  const FlashcardsViewWidget({super.key, required this.deck});

  @override
  ConsumerState<FlashcardsViewWidget> createState() => _FlashcardsViewWidgetState();
}

class _FlashcardsViewWidgetState extends ConsumerState<FlashcardsViewWidget> with SingleTickerProviderStateMixin {
  late List<FlashcardItemModel> _cards;
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _cards = widget.deck.cards;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
  }

  @override
  void didUpdateWidget(covariant FlashcardsViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck != widget.deck) {
      _cards = widget.deck.cards;
      _currentIndex = 0;
      _isFlipped = false;
      _flipController.reset();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  int get _masteredCount => _cards.where((c) => c.isMastered).length;

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const Center(child: Text('No flashcards generated yet.'));
    }

    final currentCard = _cards[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              // Progress & Mastered Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card ${_currentIndex + 1} of ${_cards.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_masteredCount Mastered',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _cards.length,
                  backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),

              // Interactive Flipping Card
              GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * pi;
                    final isUnder = angle > (pi / 2);

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: isUnder
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: Alignment.center,
                              child: _buildCardBack(context, currentCard, isDark),
                            )
                          : _buildCardFront(context, currentCard, isDark),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Tap hint
              Text(
                '💡 Tap card to ${_isFlipped ? "see front" : "reveal answer"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Navigation & Mastery Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    tooltip: 'Previous Card',
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        currentCard.isMastered = !currentCard.isMastered;
                      });
                    },
                    icon: Icon(
                      currentCard.isMastered ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: currentCard.isMastered ? const Color(0xFF10B981) : Colors.grey,
                    ),
                    label: Text(
                      currentCard.isMastered ? 'Mastered' : 'Mark as Mastered',
                      style: TextStyle(
                        color: currentCard.isMastered ? const Color(0xFF10B981) : null,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentIndex < _cards.length - 1 ? _nextCard : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    tooltip: 'Next Card',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: () {
                  ref.read(aiStudyControllerProvider.notifier).generateFlashcards();
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Generate New Deck'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(BuildContext context, FlashcardItemModel card, bool isDark) {
    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.category,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                card.front,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text('QUESTION / TERM', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(BuildContext context, FlashcardItemModel card, bool isDark) {
    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ANSWER / DEFINITION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  card.back,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (card.citation != null)
            CitationChipWidget(citation: card.citation!, index: 1)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
