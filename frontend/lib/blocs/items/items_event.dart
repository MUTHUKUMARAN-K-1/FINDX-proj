import 'dart:io';

import 'package:frontend/models/item.dart';

abstract class ItemsEvent {
  const ItemsEvent();
}

class LoadItems extends ItemsEvent {
  final bool? isLost; // null = load all, true = lost only, false = found only

  const LoadItems({this.isLost});
}

class AddItem extends ItemsEvent {
  final Item item;
  final File? image;

  const AddItem(this.item, {this.image});
}

class DeleteItem extends ItemsEvent {
  final String itemId;

  const DeleteItem(this.itemId);
}
