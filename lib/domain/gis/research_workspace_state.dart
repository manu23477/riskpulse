import 'package:flutter/foundation.dart';
import 'research_session.dart';
import 'map_composition.dart';
import 'spatial_concepts.dart';

/// Represents the exhaustive lifecycle of the Research GIS Workspace.
/// 
/// This sealed-style state model ensures that analytical results are only 
/// presented when they are authoritative and fresh.
@immutable
abstract class ResearchWorkspaceState {
  const ResearchWorkspaceState();
}

/// The workspace is open but no study area has been captured.
class WorkspaceInitial extends ResearchWorkspaceState {
  const WorkspaceInitial();
}

/// A study area has been captured; the system is ready to begin analysis.
class WorkspaceConfigured extends ResearchWorkspaceState {
  final MapExtent extent;
  const WorkspaceConfigured(this.extent);
}

/// Analysis is currently running. 
/// Previous results are hidden to prevent stale data display.
class WorkspaceProcessing extends ResearchWorkspaceState {
  final double progress;
  final String message;
  
  const WorkspaceProcessing({
    this.progress = 0.0,
    this.message = 'Initializing...',
  });
}

/// Analysis completed successfully. Both analytical and cartographic truth are ready.
class WorkspaceReady extends ResearchWorkspaceState {
  final ResearchSession session;
  final MapComposition composition;

  const WorkspaceReady({
    required this.session,
    required this.composition,
  });
}

/// The latest analysis attempt failed. 
/// Last known good results may be provided for reference but are marked as non-current.
class WorkspaceFailed extends ResearchWorkspaceState {
  final String error;
  final ResearchSession? lastKnownSession;

  const WorkspaceFailed({
    required this.error,
    this.lastKnownSession,
  });
}
