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

import 'package:ebrevet_card/scheduled_events.dart';
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

class DropDownSettingsTile extends StatelessWidget {
  final MySetting mySetting;
  final void Function()? onChanged;
  final List<DropdownMenuItem<String>> itemList;
  final bool valueValid;
  const DropDownSettingsTile(this.mySetting,
      {super.key,
      required this.itemList,
      this.valueValid = true,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    // MyLogger.entry('Re-building dropdown tile');
    return StyledListTile(
      mySetting,
      leading: mySetting.icon ??
          const Visibility(visible: false, child: Icon(Icons.person)),
      trailing: const Icon(Icons.edit),
      title: Text(
        mySetting.title,
      ),
      subtitle: styledDropDownButton(context),
    );
  }

  Widget styledDropDownButton(BuildContext context) {
    final Key key = UniqueKey();
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: DropdownButton<String>(
          key: key,
          value: valueValid ? mySetting.value : null,
          isExpanded: true,
          isDense: true,
          items: itemList,
          onChanged: (Object? value) {
            mySetting.setValue(value);
            onChanged?.call();
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
  @override
  Widget build(BuildContext context) {
    final selected = widget.mySetting.value;

    return RadioGroup<ScheduleEventsSourceID>(
      groupValue: selected,
      onChanged: (ScheduleEventsSourceID? v) {
        if (v == null) return;
        widget.mySetting.setValue(v);
        widget.onChanged?.call();
        setState(() {}); // rebuild using updated setting
      },
      child: Column(
        children: [
          for (final sourceID in ScheduleEventsSourceID.values)
            RadioListTile<ScheduleEventsSourceID>(
              value: sourceID,
              title: Text(sourceID.description),
              // No groupValue/onChanged here — RadioGroup handles it.
            ),
        ],
      ),
    );
  }
}
