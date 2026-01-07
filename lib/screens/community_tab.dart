import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/community_service.dart';
import '../models/community_model.dart';
import '../widgets/create_community_popup.dart';
import 'community_chat_screen.dart';

class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final communityService = Provider.of<CommunityService>(context);

    return Scaffold(
      body: StreamBuilder<List<CommunityModel>>(
        stream: communityService.getCommunities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No communities found. Create one!"));
          }

          final communities = snapshot.data!;
          return ListView.builder(
            itemCount: communities.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final community = communities[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: community.iconUrl != null ? NetworkImage(community.iconUrl!) : null,
                    child: community.iconUrl == null ? const Icon(Icons.groups, size: 30) : null,
                  ),
                  title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(community.description ?? "No description", maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityChatScreen(community: community),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "create_community_fab",
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateCommunityPopup(),
          );
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }
}
