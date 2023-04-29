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

import 'package:ebrevet_card/future_events.dart';
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
  final void Function()? onChanged;

  const DialogInputSettingsTile(this.mySetting, {super.key, this.onChanged});
  @override
  DialogInputSettingsTileState createState() => DialogInputSettingsTileState();
}

class DialogInputSettingsTileState extends State<DialogInputSettingsTile> {
  late TextEditingController controller;
//  String? errorText;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    controller.text = widget.mySetting.toString();
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
      leading: widget.mySetting.icon ??
          const Visibility(visible: false, child: Icon(Icons.person)),
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
          widget.mySetting.setValueFromString(stringEntered).then((_) {
            widget.onChanged?.call();
            setState(() {});
          });
        }
      },
    );
  }

  Future<String?> openEditDialog() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter ${widget.mySetting.title}'),
          content: TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter ${widget.mySetting.title}',
              // errorText: errorText,
            ),
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: controller,
            onFieldSubmitted: (text) => submitEditDialog(text),
            onSaved: (text) => submitEditDialog(text),
            validator: (val) => widget.mySetting.validator?.call(val),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  return submitEditDialog(controller.text);
                },
                child: const Text('SUBMIT'))
          ],
        ),
      );

  void submitEditDialog(String? text) {
    if (text != null) {
      Navigator.of(context).pop(text);
      //controller.clear();
    }
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
      leading: widget.mySetting.icon ??
          const Visibility(visible: false, child: Icon(Icons.person)),
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

class DropDownSettingsTile extends StatefulWidget {
  /// Settings Key string for storing the text in cache (assumed to be unique)
  final MySetting mySetting;
  final List<DropdownMenuItem<int>> itemList;
  final void Function()? onChanged;

  const DropDownSettingsTile(this.mySetting,
      {required this.itemList, super.key, this.onChanged});

  @override
  DropDownSettingsTileState createState() => DropDownSettingsTileState();
}

class DropDownSettingsTileState extends State<DropDownSettingsTile> {
  @override
  Widget build(BuildContext context) {
    return StyledListTile(
      widget.mySetting,
      leading: widget.mySetting.icon ??
          const Visibility(visible: false, child: Icon(Icons.person)),
      trailing: const Icon(Icons.edit),
      title: Text(
        widget.mySetting.title,
      ),
      subtitle: styledDropDownButton(context),
    );
  }

  Widget styledDropDownButton(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: DropdownButton<int>(
          value: widget.mySetting.value,
          isExpanded: true,
          isDense: true,
          items: widget.itemList,
          onChanged: (Object? value) {
            widget.mySetting.setValue(value);
            widget.onChanged?.call();
            setState(() {});
          },
        ),
      ),
    );
  }
}

class RadioButtonSettingsTile extends StatefulWidget {
  /// Settings Key string for storing the text in cache (assumed to be unique)
  final MySetting mySetting;
  final void Function()? onChanged;

  const RadioButtonSettingsTile(this.mySetting, {super.key, this.onChanged});

  @override
  RadioButtonSettingsTileState createState() => RadioButtonSettingsTileState();
}

class RadioButtonSettingsTileState extends State<RadioButtonSettingsTile> {
  FutureEventsSourceID? selectedSourceId;
  @override
  Widget build(BuildContext context) {
    selectedSourceId = widget.mySetting.value;

    return Column(
      children: [
        for (var sourceID in FutureEventsSourceID.values)
          ListTile(
            title: Text(sourceID.description),
            leading: Radio<FutureEventsSourceID>(
              value: sourceID,
              groupValue: selectedSourceId,
              onChanged: (FutureEventsSourceID? v) {
                widget.mySetting.setValue(v);
                widget.onChanged?.call();
                setState(() {
                  selectedSourceId = v;
                });
              },
            ),
          ),
      ],
    );
  }
}
