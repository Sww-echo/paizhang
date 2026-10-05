from pathlib import Path
import re

root = Path(__file__).resolve().parents[1] / 'lib' / 'presentation'
lines = (root / 'connected_app.dart').read_text().splitlines(keepends=True)
assert lines[20].startswith('class AuthGate ')
assert lines[812].startswith('class ConnectedRoomPage ')
assert lines[4251].startswith('String _shortId(')
renames = '''RoomHistoryPage HistoryRoomData ScoreTransfer ScoreInput ScoreTransferDialog
RoomMemberScoreTile RoundHistoryDialog RoomManagementDialog CloseVotePanel SettlementPage
AvatarPreset AvatarPresetDialog UserAvatar ConnectedActionButton ConnectedRoomTile SessionCard
ErrorCard RoomAccessErrorCard RoomFormValue RoomFormDialog JoinRoomDialog InviteScannerPage
TextInputDialog ScoreDialog activeRoundCount sessionDate sessionStatusLabel roomStatusLabel
formatHistoryDate scoreTotalsForSession memberLabel scoreUnitLabel sumChanges profileName
initialFor avatarPresets shortId'''.split()
common = "import 'package:flutter/material.dart';\nimport '../application/app_services.dart';\nimport '../domain/models.dart';\nimport '../domain/room_snapshot.dart';\nimport '../domain/repositories.dart';\n"
groups = {
 'auth_pages.dart': ([(21,395)], ['dart:async','package:app_links/app_links.dart','package:flutter/foundation.dart','../domain/invite_service.dart','home_pages.dart','room_page.dart']),
 'home_pages.dart': ([(395,813)], ['dart:async','room_page.dart','history_pages.dart','profile_page.dart','common_widgets.dart','room_widgets.dart','../domain/invite_service.dart']),
 'room_page.dart': ([(813,1942)], ['dart:async','package:flutter/services.dart','package:qr_flutter/qr_flutter.dart','package:share_plus/share_plus.dart','../application/room_controller.dart','../domain/app_error.dart','../domain/invite_service.dart','../infrastructure/backend/app_error_mapper.dart','../infrastructure/local/app_database.dart','room_widgets.dart','score_dialogs.dart','common_widgets.dart','history_pages.dart','settlement_page.dart','presentation_helpers.dart']),
 'profile_page.dart': ([(1942,2234)], ['package:image_picker/image_picker.dart','avatar_widgets.dart','common_widgets.dart','history_pages.dart']),
 'history_pages.dart': ([(2234,2500)], ['settlement_page.dart','room_widgets.dart','presentation_helpers.dart']),
 'presentation_helpers.dart': ([(2500,2537),(3381,3420),(4252,len(lines)+1)], []),
 'score_dialogs.dart': ([(2537,2703),(2757,2863),(4118,4252)], ['avatar_widgets.dart','presentation_helpers.dart']),
 'room_widgets.dart': ([(2703,2757),(2863,3126),(3573,3784)], ['avatar_widgets.dart','presentation_helpers.dart']),
 'settlement_page.dart': ([(3126,3381)], ['package:flutter/rendering.dart','package:share_plus/share_plus.dart','../domain/settlement_calculator.dart','avatar_widgets.dart','presentation_helpers.dart']),
 'avatar_widgets.dart': ([(3420,3519)], ['presentation_helpers.dart']),
 'common_widgets.dart': ([(3519,3573),(3784,4118)], ['package:mobile_scanner/mobile_scanner.dart','../domain/invite_service.dart','presentation_helpers.dart']),
}
for name in groups:
    assert not (root / name).exists(), f'Refuse overwrite: {name}'
for name, (ranges, imports) in groups.items():
    body = ''.join(''.join(lines[start-1:end-1]) for start,end in ranges)
    for word in renames:
        body = re.sub(r'\b_' + re.escape(word) + r'\b', word, body)
    prefix = common + ''.join(f"import '{item}';\n" for item in imports)
    if name == 'settlement_page.dart':
        prefix += "import 'dart:ui' as ui;\n"
    (root / name).write_text(prefix + '\n' + body)
(root / 'connected_app.dart').write_text("export 'auth_pages.dart';\nexport 'home_pages.dart';\nexport 'room_page.dart';\nexport 'profile_page.dart';\nexport 'history_pages.dart';\n")
print('Extracted 11 presentation modules without changing widget behavior.')
