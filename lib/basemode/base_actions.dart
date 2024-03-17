import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/shopsnstuff.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

const int carsPerPage = 18;
Future<void> setVehicles() async {
  if (activeSquad == null) return;
  int page = 0;
  while (true) {
    erase();
    mvaddstrc(0, 0, white, "Choosing the Right Liberal Vehicle");
    printParty(fullParty: true);
    printCars(page);
    setColor(lightGray);
    //PAGE UP
    if (page > 0) {
      mvaddstr(17, 1, previousPageStr);
    }
    //PAGE DOWN
    if ((page + 1) * carsPerPage < vehiclePool.length) {
      mvaddstr(17, 53, nextPageStr);
    }

    mvaddstr(18, 1,
        "Press a letter to specify passengers for that Liberal vehicle.");
    mvaddstr(19, 1, "Capitalize the letter to designate a driver.");
    mvaddstr(
        20, 1, "Press a number to remove that squad member from a vehicle.");
    mvaddstr(21, 1,
        "Note:  Vehicles in yellow have already been selected by another squad.");
    mvaddstr(22, 1,
        "       Vehicles in red have been selected by both this squad and another.");
    mvaddstr(23, 1,
        "       These cars may be used by both squads but not on the same day.");
    mvaddstr(24, 1, "Enter - Done");

    String input = await getKeyCaseSensitive();
    int listIndex = input.toLowerCase().codePoint - Key.a;
    int carIndex = listIndex + page * carsPerPage;
    int squadIndex = input.codePoint - '1'.codePoint;
    if (listIndex >= 0 &&
        listIndex < carsPerPage &&
        carIndex < vehiclePool.length) {
      bool driver = true;
      if (input.codePoint >= Key.a) driver = false;
      int c = 0;
      if (squad.length > 1) {
        mvaddstrc(8, 20, white,
            "Choose a Liberal to ${driver ? "drive it" : "be a passenger"}.");
        c = (await getKey()) - '1'.codePoint;
      }
      if (c >= 0 && c <= 5) {
        Creature p = squad[c];
        if (p.preferredCarId == vehiclePool[carIndex].id) {
          if (p.canWalk) {
            p.preferredDriver = driver;
          } else {
            p.preferredDriver = false;
          }
        }
      }
    } else if (squadIndex >= 0 && squadIndex < squad.length) {
      squad[squadIndex].preferredCarId = null;
      squad[squadIndex].preferredDriver = false;
    } else if (isPageUp(input.codePoint) && page > 0) {
      page--;
    } else if (isPageDown(input.codePoint) &&
        (page + 1) * carsPerPage < vehiclePool.length) {
      page++;
    } else {
      return;
    }
  }
}

void printCars(int page) {
  int x = 1, y = 10;
  for (int l = page * carsPerPage;
      l < vehiclePool.length && l < page * carsPerPage + carsPerPage;
      l++) {
    bool thisSquad = activeSquad?.members
            .any((p) => p.alive && p.preferredCarId == vehiclePool[l].id) ??
        false;
    bool anotherSquad = pool
        .where((p) => !(activeSquad?.members.contains(p) ?? false))
        .any((p) => p.preferredCarId == vehiclePool[l].id);
    if (thisSquad && anotherSquad) {
      setColor(red);
    } else if (anotherSquad) {
      setColor(yellow);
    } else if (thisSquad) {
      setColor(lightGreen);
    } else {
      setColor(lightGray);
    }

    String str =
        String.fromCharCode('A'.codePoint + (l - (page * carsPerPage)));
    //str[1] = '\x0';
    str += " - ${vehiclePool[l].fullName()}";
    mvaddstr(y, x, str);
    x += 26;
    if (x > 53) {
      x = 1;
      y++;
    }
  }
}

/* base - reorder party */
Future<void> orderparty() async {
  activeSquadMemberIndex = -1;

  int partysize = squadsize(activeSquad);

  if (partysize <= 1) return;

  while (true) {
    printParty();
    mvaddstrc(8, 26, white, "Choose squad member to move");

    int oldPos = await getKey();

    if (oldPos < Key.num1 || oldPos > partysize + Key.num1 - 1) {
      return; // User chose index out of range, exit
    }
    makeDelimiter();
    setColor(white);
    String str = "Choose squad member to replace ";
    str += squad[oldPos - Key.num1].name;
    str += " in Spot $oldPos";
    int x = 39 - ((str.length - 1) >> 1);
    if (x < 0) x = 0;
    mvaddstr(8, x, str);

    int newPos = await getKey();

    if (newPos < Key.num1 || newPos > partysize + Key.num1 - 1) {
      return; // User chose index out of range, exit
    }
    squad.swap(oldPos - Key.num1, oldPos - Key.num1);
  }
}
