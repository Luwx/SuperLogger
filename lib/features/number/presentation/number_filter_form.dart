import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/core/models/datelog.dart';

import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

// class _NumberShowLessThanFilter implements ValueFilter<double> {
//   final double val;
//   _NumberShowLessThanFilter(this.val);

//   @override
//   bool shouldRemove(Log<double> log) {
//     return log.value >= val;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is _NumberShowLessThanFilter && other.val == val;
//   }

//   @override
//   int get hashCode => val.hashCode;
// }

// class _NumberShowGreaterThanFilter implements ValueFilter<double> {
//   final double val;
//   _NumberShowGreaterThanFilter(this.val);

//   @override
//   bool shouldRemove(Log<double> log) {
//     return log.value <= val;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is _NumberShowGreaterThanFilter && other.val == val;
//   }

//   @override
//   int get hashCode => val.hashCode;
// }

// class NumberLogFilterForm extends StatefulWidget {
//   const NumberLogFilterForm({Key? key, required this.controller}) : super(key: key);

//   final ValueEitherController<IList<ValueFilter>> controller;

//   @override
//   _NumberLogFilterFormState createState() => _NumberLogFilterFormState();
// }

// class _NumberLogFilterFormState extends State<NumberLogFilterForm> {
//   String? _errorText;

//   ValueFilter? largerThan;
//   ValueFilter? lessThan;

//   late final TextEditingController _greaterThanController;
//   late final TextEditingController _lessThanController;

//   bool _isValid(String greaterThan, String lessThan) {
//     int? greaterThanVal = int.tryParse(greaterThan);
//     int? lessThanVal = int.tryParse(lessThan);

//     if (greaterThanVal != null && lessThanVal != null) {
//       return greaterThanVal >= lessThanVal;
//     }

//     return true;
//   }

//   void _textEditingListener() {
//     if (_isValid(_greaterThanController.text, _lessThanController.text)) {
//       final List<ValueFilter> filters = [];

//       double? greaterThanVal = double.tryParse(_greaterThanController.text);
//       if (greaterThanVal != null) {
//         filters.add(_NumberShowGreaterThanFilter(greaterThanVal));
//       }

//       double? lessThan = double.tryParse(_lessThanController.text);
//       if (lessThan != null) {
//         filters.add(_NumberShowLessThanFilter(lessThan));
//       }

//       widget.controller.setRightValue(filters.lock);
//       if (_errorText != null) {
//         setState(() {
//           _errorText = null;
//         });
//       }
//     } else {
//       widget.controller.setErrorValue("Invalid values");
//       if (_errorText == null) {
//         setState(() {
//           _errorText = "Invalid Values";
//         });
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     final filters = widget.controller.value.fold((l) => null, (r) => r);

//     String greaterThanText = "";
//     String lessThanText = "";
//     if (filters != null) {
//       for (final filter in filters) {
//         if (filter is _NumberShowGreaterThanFilter) {
//           greaterThanText = filter.val.toString();
//         } else if (filter is _NumberShowLessThanFilter) {
//           lessThanText = filter.val.toString();
//         }
//       }
//     }

//     _greaterThanController = TextEditingController(text: greaterThanText);
//     _lessThanController = TextEditingController(text: lessThanText);

//     _greaterThanController.addListener(_textEditingListener);
//     _lessThanController.addListener(_textEditingListener);
//   }

//   @override
//   void dispose() {
//     _greaterThanController.removeListener(_textEditingListener);
//     _lessThanController.removeListener(_textEditingListener);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: <Widget>[
//         TextFormField(
//           controller: _greaterThanController,
//           decoration: const InputDecoration(
//             isDense: true,
//             label: Text("greater than"),
//           ),
//           inputFormatters: <TextInputFormatter>[
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^-?\d{0,9}'),
//             ),
//           ],
//           keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         TextFormField(
//           controller: _lessThanController,
//           decoration: const InputDecoration(
//             isDense: true,
//             label: Text("less than"),
//           ),
//           inputFormatters: <TextInputFormatter>[
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^-?\d{0,9}'),
//             ),
//           ],
//           keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
//         ),
//       ],
//     );
//   }
// }

//
//---------------
//---------------
//---------------
//

// class _NumberShowGreaterThanTotalFilter implements DateLogFilter {
//   final double val;
//   _NumberShowGreaterThanTotalFilter(this.val);

//   @override
//   bool shouldRemove(DateLog datelog) {
//     return (datelog as DateLog<double>)
//             .logs
//             .map((log) => log.value)
//             .reduce((value, element) => element + value) <=
//         val;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is _NumberShowGreaterThanTotalFilter && other.val == val;
//   }

//   @override
//   int get hashCode => val.hashCode;
// }

// class _NumberShowLessThanTotalFilter implements DateLogFilter {
//   final double val;
//   _NumberShowLessThanTotalFilter(this.val);

//   @override
//   bool shouldRemove(DateLog datelog) {
//     return (datelog as DateLog<double>)
//             .logs
//             .map((log) => log.value)
//             .reduce((value, element) => element + value) >=
//         val;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is _NumberShowGreaterThanTotalFilter && other.val == val;
//   }

//   @override
//   int get hashCode => val.hashCode;
// }

// class NumberDateLogFilterForm extends StatefulWidget {
//   const NumberDateLogFilterForm({Key? key, required this.controller}) : super(key: key);

//   final ValueEitherController<DateLogFilter> controller;

//   @override
//   _NumberDateLogFilterFormState createState() => _NumberDateLogFilterFormState();
// }

// class _NumberDateLogFilterFormState extends State<NumberDateLogFilterForm> {
//   String? _errorText;

//   DateLogFilter? largerThanTotal;
//   DateLogFilter? lessThanTotal;

//   late final TextEditingController _greaterThanController;
//   late final TextEditingController _lessThanController;

//   bool _isValid(String greaterThan, String lessThan) {
//     int? greaterThanVal = int.tryParse(greaterThan);
//     int? lessThanVal = int.tryParse(lessThan);

//     if (greaterThanVal != null && lessThanVal != null) {
//       return greaterThanVal >= lessThanVal;
//     }

//     return true;
//   }

//   void _textEditingListener() {
//     if (_isValid(_greaterThanController.text, _lessThanController.text)) {
//       final DateLogFilter filter;

//       double? greaterThanVal = double.tryParse(_greaterThanController.text);
//       if (greaterThanVal != null) {
//         filters.add(_NumberShowGreaterThanTotalFilter(greaterThanVal));
//       }

//       double? lessThan = double.tryParse(_lessThanController.text);
//       if (lessThan != null) {
//         filters.add(_NumberShowLessThanTotalFilter(lessThan));
//       }

//       widget.controller.setRightValue(filters.lock);
//       if (_errorText != null) {
//         setState(() {
//           _errorText = null;
//         });
//       }
//     } else {
//       widget.controller.setErrorValue("Invalid values");
//       if (_errorText == null) {
//         setState(() {
//           _errorText = "Invalid Values";
//         });
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     final filters = widget.controller.value.fold((l) => null, (r) => r);

//     String greaterThanTotalText = "";
//     String lessThanTotalText = "";
//     if (filters != null) {
//       for (final filter in filters) {
//         if (filter is _NumberShowGreaterThanTotalFilter) {
//           greaterThanTotalText = filter.val.toString();
//         } else if (filter is _NumberShowLessThanTotalFilter) {
//           lessThanTotalText = filter.val.toString();
//         }
//       }
//     }

//     _greaterThanController = TextEditingController(text: greaterThanTotalText);
//     _lessThanController = TextEditingController(text: lessThanTotalText);

//     _greaterThanController.addListener(_textEditingListener);
//     _lessThanController.addListener(_textEditingListener);
//   }

//   @override
//   void dispose() {
//     _greaterThanController.removeListener(_textEditingListener);
//     _lessThanController.removeListener(_textEditingListener);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: <Widget>[
//         Text(context.l10n.totalValue),
//         TextFormField(
//           controller: _greaterThanController,
//           decoration: InputDecoration(
//               isDense: true, label: Text(context.l10n.greaterThan), errorText: _errorText),
//           inputFormatters: <TextInputFormatter>[
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^-?\d{0,9}'),
//             ),
//           ],
//           keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         TextFormField(
//           controller: _lessThanController,
//           decoration: InputDecoration(
//               isDense: true, label: Text(context.l10n.lessThan), errorText: _errorText),
//           inputFormatters: <TextInputFormatter>[
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^-?\d{0,9}'),
//             ),
//           ],
//           keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
//         ),
//       ],
//     );
//   }
// }
