/// Hand-written models for the Tool Request feature (matches the
/// hand-written style used for the newer calendering models in
/// line1_models.dart — no build_runner/freezed codegen required).

class ToolRequest {
  final String name;
  final String? targetWorkstation;
  final String status;
  final String? requestedBy;
  final String? creation;
  final String? remarks;
  final int itemCount;
  final double totalRequested;
  final double totalFulfilled;

  const ToolRequest({
    required this.name,
    this.targetWorkstation,
    this.status = 'Draft',
    this.requestedBy,
    this.creation,
    this.remarks,
    this.itemCount = 0,
    this.totalRequested = 0,
    this.totalFulfilled = 0,
  });

  factory ToolRequest.fromJson(Map<String, dynamic> json) => ToolRequest(
        name: json['name']?.toString() ?? '',
        targetWorkstation: json['target_workstation']?.toString(),
        status: json['status']?.toString() ?? 'Draft',
        requestedBy: json['requested_by']?.toString(),
        creation: json['creation']?.toString(),
        remarks: json['remarks']?.toString(),
        itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
        totalRequested: (json['total_requested'] as num?)?.toDouble() ?? 0,
        totalFulfilled: (json['total_fulfilled'] as num?)?.toDouble() ?? 0,
      );
}

class ToolRequestItem {
  final String name;
  final String toolType;
  final int qty;
  final int fulfilledQty;
  final double widthInMm;
  final double lengthInMm;
  final bool isCompleted;

  const ToolRequestItem({
    this.name = '',
    required this.toolType,
    this.qty = 1,
    this.fulfilledQty = 0,
    this.widthInMm = 0,
    this.lengthInMm = 0,
    this.isCompleted = false,
  });

  factory ToolRequestItem.fromJson(Map<String, dynamic> json) => ToolRequestItem(
        name: json['name']?.toString() ?? '',
        toolType: json['tool_type']?.toString() ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        fulfilledQty: (json['fulfilled_qty'] as num?)?.toInt() ?? 0,
        widthInMm: (json['width_in_mm'] as num?)?.toDouble() ?? 0,
        lengthInMm: (json['length_in_mm'] as num?)?.toDouble() ?? 0,
        isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      );
}

class FulfilledTool {
  final String requestItem;
  final String tool;
  final String toolType;
  final String? fulfilledAt;

  const FulfilledTool({
    required this.requestItem,
    required this.tool,
    this.toolType = '',
    this.fulfilledAt,
  });

  factory FulfilledTool.fromJson(Map<String, dynamic> json) => FulfilledTool(
        requestItem: json['request_item']?.toString() ?? '',
        tool: json['tool']?.toString() ?? '',
        toolType: json['tool_type']?.toString() ?? '',
        fulfilledAt: json['fulfilled_at']?.toString(),
      );
}

class ToolRequestDetail {
  final String name;
  final String? targetWorkstation;
  final String status;
  final int docstatus;
  final String? remarks;
  final String? creation;
  final List<ToolRequestItem> items;
  final List<FulfilledTool> fulfilledTools;

  const ToolRequestDetail({
    required this.name,
    this.targetWorkstation,
    this.status = 'Draft',
    this.docstatus = 0,
    this.remarks,
    this.creation,
    this.items = const [],
    this.fulfilledTools = const [],
  });

  factory ToolRequestDetail.fromJson(Map<String, dynamic> json) => ToolRequestDetail(
        name: json['name']?.toString() ?? '',
        targetWorkstation: json['target_workstation']?.toString(),
        status: json['status']?.toString() ?? 'Draft',
        docstatus: (json['docstatus'] as num?)?.toInt() ?? 0,
        remarks: json['remarks']?.toString(),
        creation: json['creation']?.toString(),
        items: (json['items'] as List?)
                ?.map((e) => ToolRequestItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        fulfilledTools: (json['fulfilled_tools'] as List?)
                ?.map((e) => FulfilledTool.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

/// Per-line fulfillment outcome, returned by tool_requests.fulfill.
class ToolRequestLineResult {
  final String toolType;
  final int requested;
  final int fulfilled;
  final int shortfall;
  final String? matchedSpecItemCode;
  final List<String> tools;

  const ToolRequestLineResult({
    required this.toolType,
    this.requested = 0,
    this.fulfilled = 0,
    this.shortfall = 0,
    this.matchedSpecItemCode,
    this.tools = const [],
  });

  factory ToolRequestLineResult.fromJson(Map<String, dynamic> json) => ToolRequestLineResult(
        toolType: json['tool_type']?.toString() ?? '',
        requested: (json['requested'] as num?)?.toInt() ?? 0,
        fulfilled: (json['fulfilled'] as num?)?.toInt() ?? 0,
        shortfall: (json['shortfall'] as num?)?.toInt() ?? 0,
        matchedSpecItemCode: json['matched_spec_item_code']?.toString(),
        tools: (json['tools'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class ToolRequestFulfillResult {
  final String name;
  final String status;
  final List<ToolRequestLineResult> results;

  const ToolRequestFulfillResult({
    required this.name,
    this.status = '',
    this.results = const [],
  });

  factory ToolRequestFulfillResult.fromJson(Map<String, dynamic> json) => ToolRequestFulfillResult(
        name: json['name']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        results: (json['results'] as List?)
                ?.map((e) => ToolRequestLineResult.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

/// A tool Staged at a specific workstation — the source list for the
/// station-side "pick from what's staged here" selector.
class StagedTool {
  final String toolCode;
  final String? toolName;
  final String? itemCode;
  final String? batchNo;

  const StagedTool({
    required this.toolCode,
    this.toolName,
    this.itemCode,
    this.batchNo,
  });

  factory StagedTool.fromJson(Map<String, dynamic> json) => StagedTool(
        toolCode: (json['tool_code'] ?? json['name'])?.toString() ?? '',
        toolName: json['tool_name']?.toString(),
        itemCode: json['item_code']?.toString(),
        batchNo: json['batch_no']?.toString(),
      );
}
