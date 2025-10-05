import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pet_date/domain/entities/feed_filters.dart';
import 'package:pet_date/domain/entities/match_entry.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:pet_date/domain/entities/group_request_status.dart';
import 'package:pet_date/domain/entities/group_info.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:pet_date/presentation/viewmodels/group_requests_viewmodel.dart';
import 'package:pet_date/presentation/viewmodels/home_viewmodel.dart';
import 'package:pet_date/presentation/viewmodels/matches_viewmodel.dart';
import 'package:pet_date/presentation/widgets/dialogs.dart';
import 'package:pet_date/presentation/widgets/group_card.dart';
import 'package:pet_date/presentation/widgets/match_tile.dart';
import 'package:pet_date/presentation/widgets/swipe_action_bar.dart';
import 'package:pet_date/presentation/widgets/user_card.dart';
import 'package:pet_date/data/datasources/group_firebase_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SwiperController _swiperController;
  int _feedIndex = 0;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final homeVm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Text(
          _navIndex == 0 ? 'PetLove' : 'Community',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_navIndex == 0)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () => _openFilters(homeVm),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await navigator.pushNamed('/matches');
                  if (!mounted) return;
                  await homeVm.markMatchesSeen();
                },
              ),
              if (homeVm.hasNewMatches)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await auth.signOut();
              if (!mounted) return;
              navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _FeedBody(
            swiperController: _swiperController,
            onIndexChanged: (i) => setState(() => _feedIndex = i),
            currentIndex: _feedIndex,
          ),
          CommunityTab(userId: auth.user?.id),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (value) => setState(() => _navIndex = value),
        selectedItemColor: Colors.pinkAccent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Community',
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(HomeViewModel vm) async {
    final result = await showModalBottomSheet<FeedFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FiltersSheet(
        initialFilters: vm.filters,
        availablePetTypes: vm.availablePetTypes,
      ),
    );

    if (result != null) {
      vm.updateFilters(result);
    }
  }
}

class _FeedBody extends StatelessWidget {
  final SwiperController swiperController;
  final void Function(int) onIndexChanged;
  final int currentIndex;

  const _FeedBody({
    required this.swiperController,
    required this.onIndexChanged,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        final users = vm.users;
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No more profiles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Come back later to see new profiles',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Swiper(
              controller: swiperController,
              itemBuilder: (context, index) {
                final user = users[index];
                return UserCard(
                  user: user,
                  onLike: () => _confirmAndLike(context, user),
                  onDislike: () => _confirmAndDislike(context, user),
                );
              },
              itemCount: users.length,
              itemWidth: MediaQuery.of(context).size.width,
              itemHeight: MediaQuery.of(context).size.height * 0.7,
              layout: SwiperLayout.STACK,
              onIndexChanged: onIndexChanged,
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: SwipeActionBar(
                onDislike: () => _triggerAction(context, users, currentIndex,
                    (vm, profile) => vm.dislikeUser(profile.id)),
                onSuperLike: () => _triggerAction(
                    context,
                    users,
                    currentIndex,
                    (vm, profile) async => vm
                        .superLikeUser(profile.id)
                        .then((matched) => matched)),
                onLike: () => _triggerAction(
                    context,
                    users,
                    currentIndex,
                    (vm, profile) async =>
                        vm.likeUser(profile.id).then((matched) => matched)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerAction(
    BuildContext context,
    List<UserProfile> users,
    int index,
    Future<dynamic> Function(HomeViewModel vm, UserProfile profile) action,
  ) async {
    if (users.isEmpty || index >= users.length) return;
    final profile = users[index];
    final vm = context.read<HomeViewModel>();
    final result = await action(vm, profile);
    if (result is bool && result && context.mounted) {
      await showMatchDialog(
        context,
        otherUserId: profile.id,
        otherName: profile.name,
      );
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        swiperController.next();
      } catch (_) {}
    });
  }

  void _confirmAndLike(BuildContext context, UserProfile user) {
    showActionConfirmDialog(
      context,
      title: 'You like ${user.name}!',
      message: 'You have liked this profile',
      color: Colors.green,
      icon: Icons.favorite,
      onConfirm: () async {
        final vm = context.read<HomeViewModel>();
        final matched = await vm.likeUser(user.id);
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            swiperController.next();
          } catch (_) {}
        });
        if (!context.mounted) return;
        if (matched) {
          await showMatchDialog(
            context,
            otherUserId: user.id,
            otherName: user.name,
          );
        }
      },
    );
  }

  void _confirmAndDislike(BuildContext context, UserProfile user) {
    showActionConfirmDialog(
      context,
      title: "You don't like ${user.name}",
      message: 'You have rejected this profile',
      color: Colors.red,
      icon: Icons.close,
      onConfirm: () async {
        final vm = context.read<HomeViewModel>();
        await vm.dislikeUser(user.id);
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            swiperController.next();
          } catch (_) {}
        });
      },
    );
  }
}

class CommunityTab extends StatelessWidget {
  final String? userId;

  const CommunityTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(
        child: Text('Sign in to join matches and groups'),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchesViewModel(uid: userId!)),
        ChangeNotifierProvider(
          create: (_) => GroupRequestsViewModel(
            userId: userId!,
            repository: FirebaseGroupRepository(),
          ),
        ),
      ],
      child: const _CommunityBody(),
    );
  }
}

class _CommunityBody extends StatefulWidget {
  const _CommunityBody();

  @override
  State<_CommunityBody> createState() => _CommunityBodyState();
}

class _CommunityBodyState extends State<_CommunityBody>
    with SingleTickerProviderStateMixin {
  bool _markedSeen = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.pinkAccent,
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Matches'),
              Tab(icon: Icon(Icons.groups), text: 'Groups'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MatchesList(onMarked: () {
                  if (_markedSeen) return;
                  _markedSeen = true;
                  context.read<MatchesViewModel>().markMatchesSeen();
                }),
                const _GroupsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesList extends StatefulWidget {
  final VoidCallback onMarked;
  const _MatchesList({required this.onMarked});

  @override
  State<_MatchesList> createState() => _MatchesListState();
}

class _MatchesListState extends State<_MatchesList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatchesViewModel>(builder: (context, vm, _) {
      return StreamBuilder<List<MatchEntry>>(
        stream: vm.matchEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No matches yet',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          widget.onMarked();
          final matches = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = matches[index];
              return MatchTile(
                entry: entry,
                onChat: () {
                  Navigator.pushNamed(context, '/chat', arguments: {
                    'otherUserId': entry.profile.id,
                    'otherName': entry.profile.name,
                  });
                },
                onRemove: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await vm.removeMatch(entry.profile.id);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Match removed')),
                  );
                },
              );
            },
          );
        },
      );
    });
  }
}

class _GroupsList extends StatefulWidget {
  const _GroupsList();

  @override
  State<_GroupsList> createState() => _GroupsListState();
}

class _GroupsListState extends State<_GroupsList> {
  void _toggleGroup(
    BuildContext context,
    GroupRequestsViewModel vm,
    GroupInfo group,
    GroupRequestStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (status == GroupRequestStatus.pending) {
      await vm.cancelRequest(group.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Request cancelled for ${group.name}')),
      );
    } else {
      await vm.requestJoin(group.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Request sent to ${group.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupRequestsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
            ),
          );
        }
        final groups = vm.groups;
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No groups available yet',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final status = vm.statusFor(group.id);
            return GroupCard(
              group: group,
              status: status,
              onAction: () => _toggleGroup(context, vm, group, status),
            );
          },
        );
      },
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final FeedFilters initialFilters;
  final List<String> availablePetTypes;

  const _FiltersSheet({
    required this.initialFilters,
    required this.availablePetTypes,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late RangeValues _ageRange;
  late Set<String> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.initialFilters.minAge.toDouble(),
      widget.initialFilters.maxAge.toDouble(),
    );
    _selectedTypes = Set<String>.from(widget.initialFilters.petTypes);
  }

  String _normalize(String value) => value.toLowerCase().trim();

  bool _isSelected(String type) => _selectedTypes.contains(_normalize(type));

  void _toggleType(String type) {
    final normalized = _normalize(type);
    setState(() {
      if (_selectedTypes.contains(normalized)) {
        _selectedTypes.remove(normalized);
      } else {
        _selectedTypes.add(normalized);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _ageRange = RangeValues(
        FeedFilters.defaultMinAge.toDouble(),
        FeedFilters.defaultMaxAge.toDouble(),
      );
      _selectedTypes.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      FeedFilters(
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        petTypes: _selectedTypes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petTypes = widget.availablePetTypes.isEmpty
        ? const ['Dog', 'Cat', 'Bird', 'Other']
        : widget.availablePetTypes;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Text(
                'Age range',
                style: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              RangeSlider(
                values: _ageRange,
                min: FeedFilters.defaultMinAge.toDouble(),
                max: FeedFilters.defaultMaxAge.toDouble(),
                divisions:
                    FeedFilters.defaultMaxAge - FeedFilters.defaultMinAge,
                activeColor: Colors.pinkAccent,
                labels: RangeLabels(
                  _ageRange.start.round().toString(),
                  _ageRange.end.round().toString(),
                ),
                onChanged: (values) {
                  setState(() {
                    _ageRange = RangeValues(values.start, values.end);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Min: ${_ageRange.start.round()}'),
                  Text('Max: ${_ageRange.end.round()}'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Pet types',
                style: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in petTypes)
                    FilterChip(
                      label: Text(type),
                      selected: _isSelected(type),
                      onSelected: (_) => _toggleType(type),
                      selectedColor: Colors.pinkAccent.withOpacity(0.2),
                      checkmarkColor: Colors.pinkAccent,
                      backgroundColor: Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
