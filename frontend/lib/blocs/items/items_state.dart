import 'package:frontend/models/item.dart';

abstract class ItemsState {
  const ItemsState();
}

class ItemsLoading extends ItemsState {}

class ItemsLoaded extends ItemsState {
  final List<Item> items;

  const ItemsLoaded(this.items);
}

class ItemsError extends ItemsState {
  final String message;

  const ItemsError(this.message);
}