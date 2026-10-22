import 'package:flutter/material.dart';

import 'app_layout.dart';
import 'catalog_sort.dart';
import 'core_bridge.dart';
import 'drama_actions.dart';
import 'follow_state.dart';
import 'local_store.dart';
import 'models.dart';
import 'remote_widgets.dart';
import 'widgets.dart';

class SavedLibrary extends StatefulWidget {
  const SavedLibrary({
    super.key,
    required this.repository,
    required this.store,
    required this.history,
    required this.onOpen,
    required this.onContinue,
    this.onDownload,
  });

  final AppRepository repository;
  final LocalStore store;
  final bool history;
  final ValueChanged<Drama> onOpen;
  final ValueChanged<Drama> onContinue;
  final ValueChanged<Drama>? onDownload;

  @override
  State<SavedLibrary> createState() => _SavedLibraryState();
}

class _SavedLibraryState extends State<SavedLibrary> {
  final _search = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _clearHistory() async {
    final epoch = widget.store.profileEpoch;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空观看记录？'),
        content: const Text('这会删除当前用户的观看进度，追剧状态和手动已看标记会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted && epoch == widget.store.profileEpoch) {
      await saveUserChange(context, widget.store.clearHistory);
    }
  }

  void _actions(Drama drama) => showDramaActions(
    context,
    drama: drama,
    store: widget.store,
    history: widget.history,
    onContinue: () => widget.onContinue(drama),
    onDownload: widget.onDownload == null
        ? null
        : () => widget.onDownload!(drama),
  );

  Widget _tile(Drama drama, {FocusNode? focusNode, VoidCallback? onFocus}) {
    final watched = widget.store.watched(drama.id);
    final state = widget.store.following(drama.id);
    final badge = state == null
        ? null
        : '${state.label}${state.hasUpdates ? ' · ${state.updateLabel}' : ''}';
    return DramaTile(
      key: ValueKey('saved-${drama.id}'),
      drama: drama,
      repository: widget.repository,
      focusNode: focusNode,
      onFocus: onFocus,
      onTap: () => widget.onOpen(drama),
      onMore: () => _actions(drama),
      actions: DramaActionButton(
        drama: drama,
        onPressed: () => _actions(drama),
      ),
      badge: badge,
      subtitle: watched == null
          ? SourceSite.byId(drama.source).name
          : '第 ${watched.episode} 集 · ${formatPosition(watched.position)}',
    );
  }

  Widget _historyRow(Drama drama, WatchEntry? entry) {
    final episode = entry?.episode ?? 0;
    final total = drama.episodes;
    final progress = (entry == null || entry.duration <= 0)
        ? null
        : (entry.position / entry.duration).clamp(0.0, 1.0);
    final updated = entry == null
        ? ''
        : _relativeTime(entry.updatedAt);
    return Card(
      key: ValueKey('history-${drama.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onOpen(drama),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 88,
                child: DramaCover(
                  drama: drama,
                  repository: widget.repository,
                  radius: 8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drama.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        total > 0 ? '看至第$episode集/共$total集' : '看至第$episode集',
                        if (entry != null) formatPosition(entry.position),
                        if (updated.isNotEmpty) updated,
                      ].join('  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                key: ValueKey('history-resume-${drama.id}'),
                onPressed: () => widget.onContinue(drama),
                child: const Text('继续播放'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
    if (difference.inHours < 24) return '${difference.inHours}小时前';
    if (difference.inDays < 30) return '${difference.inDays}天前';
    return '${time.year}-${time.month}-${time.day}';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final history = widget.store.history;
      final all = widget.history
          ? history.map((entry) => entry.drama).toList()
          : widget.store.favorites;
      final items = all.where((drama) {
        if (!matchesDramaQuery(drama, _search.text)) return false;
        final state = widget.store.following(drama.id);
        return widget.history ||
            _filter.isEmpty ||
            (_filter == 'updates'
                ? state?.hasUpdates == true
                : state?.status.name == _filter);
      }).toList();
      final ids = items.map((drama) => drama.id).toSet();
      final resume = history
          .where(
            (entry) =>
                ids.contains(entry.drama.id) &&
                (!entry.finished ||
                    entry.drama.episodes <= 0 ||
                    entry.episode < entry.drama.episodes),
          )
          .firstOrNull;
      final header = [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.history ? '最近观看' : '我的追剧'} · ${all.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.history && all.isNotEmpty)
                IconButton(
                  tooltip: '清空观看记录',
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: RemoteTextInput(
            child: TextField(
              key: ValueKey(
                widget.history ? 'history-search' : 'favorites-search',
              ),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.history ? '搜索观看记录' : '搜索追剧',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空搜索',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
        ),
        if (!widget.history)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (final filter in [
                  ('', '全部'),
                  for (final status in FollowStatus.values)
                    (status.name, status.label),
                  ('updates', '有更新'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: ValueKey('follow-filter-${filter.$1}'),
                      label: Text(filter.$2),
                      selected: _filter == filter.$1,
                      onSelected: (_) => setState(() => _filter = filter.$1),
                    ),
                  ),
              ],
            ),
          ),
        if (resume != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                key: const ValueKey('continue-watching'),
                leading: const Icon(Icons.play_circle_outline),
                title: Text(
                  '继续观看 · ${resume.drama.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '第 ${resume.episode} 集 · ${formatPosition(resume.position)}',
                ),
                onTap: () => widget.onContinue(resume.drama),
              ),
            ),
          ),
      ];
      final empty = StatusPanel(
        title: all.isEmpty
            ? widget.history
                  ? '还没有观看记录'
                  : '还没有追剧'
            : '没有匹配的记录',
        message: all.isEmpty ? '去发现页，挑一部喜欢的短剧。' : '可以更换搜索词或筛选条件。',
        icon: widget.history
            ? Icons.history_rounded
            : Icons.bookmark_border_rounded,
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          if (AppLayout.isTelevision(context)) {
            final columns = ((constraints.maxWidth - 36) / 150).floor().clamp(
              1,
              8,
            );
            final tileWidth =
                (constraints.maxWidth - 36 - (columns - 1) * 14) / columns;
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * .5,
                  ),
                  child: SingleChildScrollView(child: Column(children: header)),
                ),
                Expanded(
                  child: items.isEmpty
                      ? empty
                      : RemoteGrid(
                          key: ValueKey(
                            'saved-tv-${widget.history}-$_filter-${_search.text}',
                          ),
                          itemKeys: items.map((item) => item.id).toList(),
                          columns: columns,
                          itemExtent:
                              DramaTile.extentFor(context, tileWidth - 14) + 14,
                          itemBuilder: (_, index, node, onFocus) => _tile(
                            items[index],
                            focusNode: node,
                            onFocus: onFocus,
                          ),
                        ),
                ),
              ],
            );
          }
          final padding = constraints.maxWidth < 600 ? 16.0 : 24.0;
          return CustomScrollView(
            key: PageStorageKey(
              'saved-${widget.history}-$_filter-${_search.text}',
            ),
            slivers: [
              SliverToBoxAdapter(child: Column(children: header)),
              if (items.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: empty)
              else if (widget.history)
                // 红果风格历史列表：封面 + 标题 + 进度 + 继续播放按钮。
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final drama = items[index];
                      final entry = history
                          .where((entry) => entry.drama.id == drama.id)
                          .firstOrNull;
                      return _historyRow(drama, entry);
                    }, childCount: items.length),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 20),
                  sliver: SliverGrid(
                    gridDelegate: dramaGridDelegate(
                      context,
                      constraints.maxWidth - 2 * padding,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => _tile(items[index]),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
