import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/match_entry.dart';
import 'package:pet_date/domain/entities/group_info.dart';
import 'package:pet_date/domain/entities/group_request_status.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:pet_date/presentation/viewmodels/matches_viewmodel.dart';
import 'package:pet_date/presentation/viewmodels/group_requests_viewmodel.dart';
import 'package:pet_date/data/datasources/group_firebase_repository.dart';
import 'package:pet_date/presentation/widgets/group_card.dart';
import 'package:pet_date/presentation/widgets/match_tile.dart';
import 'package:provider/provider.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final uid = auth.user?.id;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: const Text('Matches', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('Sign in to see your matches')),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchesViewModel(uid: uid)),
        ChangeNotifierProvider(
          create: (_) => GroupRequestsViewModel(
            userId: uid,
            repository: FirebaseGroupRepository(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.pinkAccent,
            title: Text(
              _currentIndex == 0 ? 'Matches' : 'Groups',
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body:
              _currentIndex == 0 ? const _MatchesListTab() : const _GroupsTab(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (value) => setState(() => _currentIndex = value),
            selectedItemColor: Colors.pinkAccent,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Matches',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: 'Groups',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchesListTab extends StatefulWidget {
  const _MatchesListTab();

  @override
  State<_MatchesListTab> createState() => _MatchesListTabState();
}

class _MatchesListTabState extends State<_MatchesListTab> {
  bool _markedSeen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_markedSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<MatchesViewModel>().markMatchesSeen();
      });
      _markedSeen = true;
    }
  }

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
          final matches = snapshot.data!;
          return ListView.separated(
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

class _GroupsTab extends StatefulWidget {
  const _GroupsTab();

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
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
