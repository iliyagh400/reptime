import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCheckinPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const AddCheckinPage({super.key, required this.pet});

  @override
  State<AddCheckinPage> createState() => _AddCheckinPageState();
}

class _AddCheckinPageState extends State<AddCheckinPage> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  int _healthScore = 8;
  bool _isLoading = false;

  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _moss = Color(0xFF6E8B52);
  static const _lightMoss = Color(0xFF879B5D);
  static const _leaf = Color(0xFF486344);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _text = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _line = Color(0xFF3A463C);

  @override
  void initState() {
    super.initState();
    final currentWeight = widget.pet['weight'];
    if (currentWeight != null) {
      _weightController.text = currentWeight.toString();
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final weight = double.tryParse(_weightController.text.trim());

      await Supabase.instance.client.from('pet_checkins').insert({
        'user_id': userId,
        'pet_id': widget.pet['id'],
        'weight': weight,
        'health_score': _healthScore,
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'checkin_date': DateTime.now().toIso8601String(),
      });

      // Keep the pet's main weight field in sync with the latest check-in
      // so the rest of the app (forms, etc.) shows the current value.
      if (weight != null) {
        await Supabase.instance.client
            .from('pets')
            .update({'weight': weight}).eq('id', widget.pet['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اطلاعات ثبت شد ✅')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({required String label, required IconData icon, String? hint}) => InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon,color:_muted,size:20), labelStyle: const TextStyle(color:_muted), hintStyle: const TextStyle(color:_muted), filled:true, fillColor:_surface, contentPadding: const EdgeInsets.symmetric(horizontal:16,vertical:16), border: OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:_line)), enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:_line)), focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:_lightMoss,width:1.5)));

  Widget _section(String title, IconData icon) => Padding(padding:const EdgeInsets.fromLTRB(2,22,2,10),child:Row(children:[Container(width:30,height:30,decoration:BoxDecoration(color:_leaf.withOpacity(.32),borderRadius:BorderRadius.circular(10)),child:Icon(icon,color:_lightMoss,size:16)),const SizedBox(width:9),Text(title,style:const TextStyle(color:_lightMoss,fontSize:12,fontWeight:FontWeight.w800))]));

  Widget _petCard() { final name=widget.pet['name']?.toString() ?? 'حیوان'; return Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(22),border:Border.all(color:_line),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.13),blurRadius:18,offset:const Offset(0,7))]),child:Row(children:[Container(width:54,height:54,decoration:BoxDecoration(gradient:LinearGradient(colors:[_lightMoss.withOpacity(.24),_leaf.withOpacity(.34)]),borderRadius:BorderRadius.circular(17)),child:const Icon(Icons.pets_rounded,color:_lightMoss,size:29)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_text,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('ثبت وضعیت و اطلاعات جدید',style:TextStyle(color:_muted,fontSize:11.5))]))])); }

  Widget _healthCard() => Container(padding:const EdgeInsets.fromLTRB(16,16,16,13),decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:_line)),child:Column(children:[Row(children:[const Icon(Icons.favorite_rounded,color:_terracotta,size:21),const SizedBox(width:9),const Text('نمره سلامت',style:TextStyle(color:_text,fontSize:14,fontWeight:FontWeight.w800)),const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:6),decoration:BoxDecoration(color:_terracotta.withOpacity(.13),borderRadius:BorderRadius.circular(11)),child:Text('$_healthScore / 10',style:const TextStyle(color:_terracotta,fontSize:13,fontWeight:FontWeight.w900)))]),const SizedBox(height:8),SliderTheme(data:SliderTheme.of(context).copyWith(activeTrackColor:_lightMoss,inactiveTrackColor:_line,thumbColor:_sand,overlayColor:_lightMoss.withOpacity(.12),trackHeight:5,thumbShape:const RoundSliderThumbShape(enabledThumbRadius:9)),child:Slider(value:_healthScore.toDouble(),min:1,max:10,divisions:9,label:'$_healthScore',onChanged:(v)=>setState(()=>_healthScore=v.round()))),const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('نیاز به توجه',style:TextStyle(color:_muted,fontSize:10)),Text('وضعیت عالی',style:TextStyle(color:_muted,fontSize:10))]) ]));

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:_background,appBar:AppBar(backgroundColor:_background,elevation:0,surfaceTintColor:Colors.transparent,iconTheme:const IconThemeData(color:_text),title:const Text('بروزرسانی حیوان',style:TextStyle(color:_text,fontSize:20,fontWeight:FontWeight.w800))),body:ListView(padding:const EdgeInsets.fromLTRB(18,5,18,32),children:[_petCard(),_section('وزن فعلی',Icons.monitor_weight_outlined),TextField(controller:_weightController,keyboardType:const TextInputType.numberWithOptions(decimal:true),style:const TextStyle(color:_text,fontSize:15,fontWeight:FontWeight.w700),decoration:_inputDecoration(label:'وزن (گرم)',icon:Icons.scale_rounded,hint:'مثلاً 450')),_section('وضعیت سلامت',Icons.favorite_outline_rounded),_healthCard(),_section('یادداشت',Icons.notes_rounded),TextField(controller:_noteController,maxLines:4,style:const TextStyle(color:_text,fontSize:14,height:1.5),decoration:_inputDecoration(label:'یادداشت (اختیاری)',icon:Icons.edit_note_rounded,hint:'مثلاً اشتهاش خوبه، فعاله و رفتار طبیعی داره')),const SizedBox(height:30),_isLoading?Container(height:55,decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(17),border:Border.all(color:_line)),child:const Center(child:SizedBox(width:23,height:23,child:CircularProgressIndicator(color:_lightMoss,strokeWidth:2.5)))):Container(height:55,decoration:BoxDecoration(gradient:const LinearGradient(colors:[_lightMoss,_moss]),borderRadius:BorderRadius.circular(17),boxShadow:[BoxShadow(color:_moss.withOpacity(.24),blurRadius:17,offset:const Offset(0,7))]),child:Material(color:Colors.transparent,child:InkWell(borderRadius:BorderRadius.circular(17),onTap:_save,child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.check_rounded,color:_background,size:23),SizedBox(width:9),Text('ثبت اطلاعات',style:TextStyle(color:_background,fontSize:15,fontWeight:FontWeight.w900))]))))])));
  }
}
