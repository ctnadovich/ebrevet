// Copyright (C) 2023 Chris Nadovich
// This file is part of eBrevet <https://github.com/ctnadovich/ebrevet>.
//
// eBrevet is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// eBrevet is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with eBrevet.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';

import 'my_settings.dart';

class StyledListTile extends StatelessWidget {
  final MySetting mySetting;

  final void Function()? onTap;
  final Widget? leading;
  final Widget? trailing;
  final Widget? title;
  final Widget? subtitle;

  const StyledListTile(
    this.mySetting, {
    super.key,
    this.onTap,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    var spacer = const SizedBox(
      height: 4,
    );
    return Material(
      // for some reason tiles need a material background
      color: Colors.transparent,
      child: Column(
        children: [
          spacer,
          ListTile(
            onTap: onTap,
            leading: leading,
            tileColor: Theme.of(context).colorScheme.onPrimary,
            trailing: trailing,
            subtitle: subtitle,
            title: title,
          ),
          spacer
        ],
      ),
    );
  }
}

class DialogInputSettingsTile extends StatefulWidget {
  final MySetting mySetting;
  const DialogInputSettingsTile(this.mySetting, {super.key});
  @override
  DialogInputSettingsTileState createState() => DialogInputSettingsTileState();
}

class DialogInputSettingsTileState extends State<DialogInputSettingsTile> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledListTile(
      widget.mySetting,
      leading: const Icon(Icons.person),
      trailing: const Icon(Icons.edit),
      title: Text(widget.mySetting.title),
      subtitle: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
        child: Text(
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer),
          widget.mySetting.value.toString(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      onTap: () async {
        final stringEntered = await openEditDialog();
        if (stringEntered != null) {
          widget.mySetting
              .setValueFromString(stringEntered)
              .then((_) => setState(() {}));
        }
      },
    );
  }

  Future<String?> openEditDialog() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter ${widget.mySetting.title}'),
          content: TextField(
            decoration:
                InputDecoration(hintText: 'Enter ${widget.mySetting.title}'),
            autofocus: true,
            controller: controller,
            onSubmitted: (_) => submitEditDialog(),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  return submitEditDialog();
                },
                child: const Text('SUBMIT'))
          ],
        ),
      );

  void submitEditDialog() {
    // widget.mySetting.setValue(controller.value);
    Navigator.of(context).pop(controller.text);
    controller.clear();
  }
}

class DropDownSettingsTile extends StatefulWidget {
  /// Settings Key string for storing the text in cache (assumed to be unique)
  final MySetting mySetting;

  const DropDownSettingsTile(this.mySetting, {super.key});

  @override
  DropDownSettingsTileState createState() => DropDownSettingsTileState();
}

class DropDownSettingsTileState extends State<DropDownSettingsTile> {
  @override
  Widget build(BuildContext context) {
    return const Text('Implementation goes here');
  }
}

class RadioSettingsTile extends StatefulWidget {
  /// Settings Key string for storing the text in cache (assumed to be unique)
  final MySetting mySetting;

  const RadioSettingsTile(this.mySetting, {super.key});

  @override
  RadioSettingsTileState createState() => RadioSettingsTileState();
}

class RadioSettingsTileState extends State<RadioSettingsTile> {
  @override
  Widget build(BuildContext context) {
    return const Text('Implementation goes here');
  }
}

class SwitchSettingsTile extends StatefulWidget {
  /// Settings Key string for storing the text in cache (assumed to be unique)
  final MySetting mySetting;

  const SwitchSettingsTile(this.mySetting, {super.key});

  @override
  SwitchSettingsTileState createState() => SwitchSettingsTileState();
}

class SwitchSettingsTileState extends State<SwitchSettingsTile> {
  @override
  Widget build(BuildContext context) {
    return StyledListTile(
      widget.mySetting,
      leading: const Icon(Icons.person),
      title: Text(widget.mySetting.title),
      trailing: Switch(
        // This bool value toggles the switch.
        value: widget.mySetting.value,
        // activeColor: Theme.of(context).colorScheme.,
        onChanged: (bool value) {
          // This is called when the user toggles the switch.
          setState(() {
            widget.mySetting.setValue(value);
          });
        },
      ),
    );
  }
}
