import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/catalog.dart';
import '../data/item.dart';
import '../data/user.dart';
import '../models/items_model.dart';
import '../widgets/button_spinner.dart';
import '../widgets/form_dropdown.dart';
import '../widgets/photo_strip.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _category;
  String? _size;
  String? _condition;

  // Эфемерное состояние: «запрос летит», поэтому setState, а не модель.
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // Валидный submit ПИШЕТ в модель через repository, затем уходит.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута

    final items = context.read<ItemsModel>();
    final owner = context.read<User>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final openedFromFeed =
        GoRouterState.of(context).matchedLocation.startsWith('/feed');

    final draft = Item(
      id: '', // временный id: настоящую идентичность даст хранилище (на L5: сервер)
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text),
      size: _size!,
      condition: _condition!,
      category: catalogCategories.firstWhere((c) => c.id == _category),
      owner: owner,
      status: ItemStatus.available,
      createdAt: DateTime.now(),
    );

    setState(() => _saving = true);
    final error = await items.add(draft);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _saving = false);

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error))); // данные остаются
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Опубликовано: ${draft.title}'),
        // из ленты своих вещей не видно, поэтому даём путь к ним
        action: openedFromFeed
            ? SnackBarAction(
                label: 'Мои вещи',
                onPressed: () => router.go('/my-items'),
              )
            : null,
      ),
    );
    context.pop(); // список позади УЖЕ вырос, без единого лишнего вызова
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новое объявление')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PhotoStrip(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: "Например: Джинсы Levi's 501",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Название обязательно';
                }
                if (value.trim().length < 3) {
                  return 'Минимум 3 символа';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Материал, дефекты, как сидит',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Добавьте описание';
                }
                if (value.trim().length < 10) {
                  return 'Минимум 10 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FormDropdown(
              label: 'Категория',
              value: _category,
              options: {for (final c in catalogCategories) c.id: c.name},
              onChanged: (v) => setState(() => _category = v),
              validator: (value) => value == null ? 'Выберите категорию' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormDropdown(
                    label: 'Размер',
                    value: _size,
                    options: {for (final s in catalogSizes) s: s},
                    onChanged: (v) => setState(() => _size = v),
                    validator: (value) =>
                        value == null ? 'Выберите размер' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormDropdown(
                    label: 'Состояние',
                    value: _condition,
                    options: {for (final c in catalogConditions) c: c},
                    onChanged: (v) => setState(() => _condition = v),
                    validator: (value) =>
                        value == null ? 'Укажите состояние' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Цена',
                suffixText: 'MDL',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final price = double.tryParse(value ?? '');
                if (price == null) return 'Введите число';
                if (price <= 0) return 'Цена должна быть положительной';
                if (price > 100000) return 'Максимум 100 000 MDL';
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const ButtonSpinner(size: 22)
                  : const Text('Опубликовать'),
            ),
          ],
        ),
      ),
    );
  }
}
