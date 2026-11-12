// Styles Google Maps « Grandpublic » : fond doux, routes lisibles, POI masqués (sauf parcs), eau bleutée.
const String kClubMapStyleLight = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f7f3ea"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5b5648"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#fbf8f1"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#dcebc8"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e9e2d0"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fff3c4"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ffd84d"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#e8b800"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#d9d0b8"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#bfe0f2"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5d8ea6"}]}
]
''';

const String kClubMapStyleDark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#15151a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9a9aa6"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#15151a"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1b2a1f"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#262630"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1c1c24"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#33333f"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#6b5a10"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#3d3308"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#33333f"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e2230"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4d7287"}]}
]
''';
