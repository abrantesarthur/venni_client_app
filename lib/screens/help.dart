import 'package:flutter/material.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';

class Help extends StatefulWidget {
  static const routeName = "Help";

  @override
  HelpState createState() => HelpState();
}

class HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return GoBackScaffold(title: "Ajuda", children: [
      Text(
        "Precisa de ajuda? Envie um email para suporte@venni.app e responderemos em até 24 horas.",
      ),
      Text("\nExemplos de coisas com que podemos ajudar: "),
      Text("\nComo usar o aplicativo"),
      Text("\nReportar direção perigosa"),
      Text("\nMotorista não era o mesmo"),
      Text("\nProblemas com a cobrança"),
      Text("\nA moto ou capacete estava em condições ruins"),
    ]);
  }
}
