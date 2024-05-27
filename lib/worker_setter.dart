import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'main.dart';

import 'package:http/http.dart' as http;
import 'package:dartx/dartx.dart';
import 'package:ollama_dart/ollama_dart.dart' as llama;

void setHost(BuildContext context, [String host = ""]) {
  bool loading = false;
  bool invalidHost = false;
  bool invalidUrl = false;
  final hostInputController =
      TextEditingController(text: prefs?.getString("host") ?? "");
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => PopScope(
              canPop: false,
              child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!.hostDialogTitle),
                  content: loading
                      ? const LinearProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(AppLocalizations.of(context)!
                                  .hostDialogDescription),
                              invalidHost
                                  ? Text(
                                      AppLocalizations.of(context)!
                                          .hostDialogErrorInvalidHost,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))
                                  : const SizedBox.shrink(),
                              invalidUrl
                                  ? Text(
                                      AppLocalizations.of(context)!
                                          .hostDialogErrorInvalidUrl,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))
                                  : const SizedBox.shrink(),
                              const SizedBox(height: 8),
                              TextField(
                                  controller: hostInputController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                      hintText: "http://example.com:8080"))
                            ]),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          setState(() {
                            loading = true;
                            invalidUrl = false;
                            invalidHost = false;
                          });
                          var tmpHost = hostInputController.text
                              .trim()
                              .removeSuffix("/")
                              .trim();

                          if (tmpHost.isEmpty) {
                            setState(() {
                              loading = false;
                            });
                            return;
                          }

                          var url = Uri.parse(tmpHost);
                          if (!url.isAbsolute) {
                            setState(() {
                              invalidUrl = true;
                              loading = false;
                            });
                            return;
                          }

                          var request = await http.get(url);
                          if (request.statusCode != 200 ||
                              request.body != "Ollama is running") {
                            setState(() {
                              invalidHost = true;
                              loading = false;
                            });
                          } else {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                            host = tmpHost;
                            prefs?.setString("host", host);
                          }
                        },
                        child:
                            Text(AppLocalizations.of(context)!.hostDialogSave))
                  ]))));
}

void setModel(BuildContext context, Function setState) {
  List<String> models = [];
  int usedIndex = -1;
  bool loaded = false;
  Function? setModalState;
  void load() async {
    var list = await llama.OllamaClient(baseUrl: "$host/api").listModels();
    for (var i = 0; i < list.models!.length; i++) {
      models.add(list.models![i].model!.split(":")[0]);
    }
    for (var i = 0; i < models.length; i++) {
      if (models[i] == model) {
        usedIndex = i;
      }
    }
    loaded = true;
    setModalState!(() {});
  }

  load();

  if (useModel) return;
  HapticFeedback.selectionClick();
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setLocalState) {
          setModalState = setLocalState;
          return PopScope(
              canPop: loaded,
              onPopInvoked: (didPop) {
                model = (usedIndex >= 0) ? models[usedIndex] : null;
                if (model != null) {
                  prefs?.setString("model", model!);
                } else {
                  prefs?.remove("model");
                }
                setState(() {});
              },
              child: SizedBox(
                  width: double.infinity,
                  child: (!loaded)
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: LinearProgressIndicator())
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, top: 16),
                              child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                      onPressed: () {},
                                      label: Text(AppLocalizations.of(context)!
                                          .modelDialogAddModel),
                                      icon: const Icon(Icons.add_rounded)))),
                          const Divider(),
                          Padding(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 16),
                              child: Container(
                                  // height: MediaQuery.of(context)
                                  //         .size
                                  //         .height *
                                  //     0.4,
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.4),
                                  child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Wrap(
                                        spacing: 5.0,
                                        alignment: WrapAlignment.center,
                                        children: List<Widget>.generate(
                                          models.length,
                                          (int index) {
                                            return ChoiceChip(
                                              label: Text(models[index]),
                                              selected: usedIndex == index,
                                              checkmarkColor: (usedIndex ==
                                                      index)
                                                  ? ((MediaQuery.of(context)
                                                              .platformBrightness ==
                                                          Brightness.light)
                                                      ? (theme ?? ThemeData())
                                                          .colorScheme
                                                          .secondary
                                                      : (themeDark ??
                                                              ThemeData.dark())
                                                          .colorScheme
                                                          .secondary)
                                                  : null,
                                              labelStyle: (usedIndex == index)
                                                  ? TextStyle(
                                                      color: (MediaQuery.of(
                                                                      context)
                                                                  .platformBrightness ==
                                                              Brightness.light)
                                                          ? (theme ??
                                                                  ThemeData())
                                                              .colorScheme
                                                              .secondary
                                                          : (themeDark ??
                                                                  ThemeData
                                                                      .dark())
                                                              .colorScheme
                                                              .secondary)
                                                  : null,
                                              selectedColor: (MediaQuery.of(
                                                              context)
                                                          .platformBrightness ==
                                                      Brightness.light)
                                                  ? (theme ?? ThemeData())
                                                      .colorScheme
                                                      .primary
                                                  : (themeDark ??
                                                          ThemeData.dark())
                                                      .colorScheme
                                                      .primary,
                                              onSelected: (bool selected) {
                                                setLocalState(() {
                                                  usedIndex =
                                                      selected ? index : -1;
                                                });
                                              },
                                            );
                                          },
                                        ).toList(),
                                      ))))
                        ])));
        });
      });
}