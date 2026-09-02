import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEventPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const AddEventPage({super.key, required this.pet});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _moss = Color(0xFF6E8B52);
  static const _lightMoss = Color(0xFF879B5D);
  static const _leaf = Color(0xFF486344);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _text = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _line = Color(0xFF3A463C);

  final List<String> _quickOptions = [
    'مریض شد',
    'پوست انداخت',
    'جاش عوض شد',
    'دستشویی کرد',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('توضیح اتفاق رو بنویس')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('pet_events').insert({
        'user_id': userId,
        'pet_id': widget.pet['id'],
        'description': _descriptionController.text.trim(),
        'event_date': _selectedDate.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اتفاق ثبت شد ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration() => InputDecoration(
    labelText: 'توضیح اتفاق',
    hintText: 'مثلاً: امروز یک تخم گذاشت',
    labelStyle: const TextStyle(color: _muted),
    hintStyle: const TextStyle(color: _muted),
    prefixIcon: const Icon(Icons.edit_note_rounded, color: _muted),
    filled: true, fillColor: _surface, alignLabelWithHint: true,
    contentPadding: const EdgeInsets.all(17),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: _line)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: _line)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: _lightMoss, width: 1.5)),
  );

  Widget _section(String title, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: _leaf.withOpacity(.32), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _lightMoss, size: 16)),
      const SizedBox(width: 9), Text(title, style: const TextStyle(color: _lightMoss, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _petCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.13), blurRadius: 18, offset: const Offset(0,7))]),
    child: Row(children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [_lightMoss.withOpacity(.24), _leaf.withOpacity(.34)]), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.pets_rounded, color: _lightMoss, size: 29)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.pet['name'] ?? 'حیوان', style: const TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5), const Text('ثبت یک اتفاق در تاریخچه حیوان', style: TextStyle(color: _muted, fontSize: 11.5)),
      ])),
    ]),
  );

  Widget _quickChip(String option) => ActionChip(
    label: Text(option),
    onPressed: () => setState(() => _descriptionController.text = option),
    backgroundColor: _surfaceRaised, side: const BorderSide(color: _line),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    labelStyle: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w700),
    avatar: const Icon(Icons.flash_on_rounded, size: 16, color: _sand),
  );

  Widget _dateCard() {
    final date='${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2,'0')}/${_selectedDate.day.toString().padLeft(2,'0')}';
    return Material(color: Colors.transparent, child: InkWell(onTap: _pickDate, borderRadius: BorderRadius.circular(17), child: Container(
      padding: const EdgeInsets.symmetric(horizontal:16, vertical:15),
      decoration: BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(17),border:Border.all(color:_line)),
      child: Row(children:[
        Container(width:40,height:40,decoration:BoxDecoration(color:_sand.withOpacity(.12),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.calendar_month_rounded,color:_sand,size:21)),
        const SizedBox(width:12), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('تاریخ اتفاق',style:TextStyle(color:_muted,fontSize:10.5)),const SizedBox(height:3),Text(date,style:const TextStyle(color:_text,fontSize:14,fontWeight:FontWeight.w800))])),
        const Icon(Icons.chevron_left_rounded,color:_muted),
      ]),
    )));
  }

  Widget _saveButton() => _isLoading ? Container(height:55,decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(17),border:Border.all(color:_line)),child:const Center(child:SizedBox(width:23,height:23,child:CircularProgressIndicator(color:_lightMoss,strokeWidth:2.5)))) : Container(
    height:55, decoration:BoxDecoration(gradient:const LinearGradient(colors:[_lightMoss,_moss]),borderRadius:BorderRadius.circular(17),boxShadow:[BoxShadow(color:_moss.withOpacity(.24),blurRadius:17,offset:const Offset(0,7))]),
    child:Material(color:Colors.transparent,child:InkWell(onTap:_saveEvent,borderRadius:BorderRadius.circular(17),child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.add_task_rounded,color:_background,size:22),SizedBox(width:9),Text('ثبت اتفاق',style:TextStyle(color:_background,fontSize:15,fontWeight:FontWeight.w900))]))),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor:_background,
      appBar:AppBar(backgroundColor:_background,elevation:0,surfaceTintColor:Colors.transparent,iconTheme:const IconThemeData(color:_text),title:Text('اتفاق جدید برای ${widget.pet['name'] ?? ''}',style:const TextStyle(color:_text,fontSize:19,fontWeight:FontWeight.w800))),
      body:ListView(padding:const EdgeInsets.fromLTRB(18,5,18,32),children:[
        _petCard(),
        _section('انتخاب سریع',Icons.bolt_rounded),
        Wrap(spacing:8,runSpacing:8,children:_quickOptions.map(_quickChip).toList()),
        _section('شرح اتفاق',Icons.notes_rounded),
        TextField(controller:_descriptionController,maxLines:4,style:const TextStyle(color:_text,fontSize:14,height:1.5),decoration:_inputDecoration()),
        _section('زمان اتفاق',Icons.event_rounded),
        _dateCard(),
        const SizedBox(height:30),
        _saveButton(),
      ]),
    ));
  }
}
