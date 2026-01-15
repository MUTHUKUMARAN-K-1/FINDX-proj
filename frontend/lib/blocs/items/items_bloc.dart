import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:frontend/api/items_repository.dart';
import 'package:frontend/blocs/items/items_event.dart';
import 'package:frontend/blocs/items/items_state.dart';
import 'package:frontend/models/item.dart';

class ItemsBloc extends Bloc<ItemsEvent, ItemsState> {
  final ItemsRepository _itemsRepository;
  StreamSubscription? _itemsSubscription;

  ItemsBloc({required ItemsRepository itemsRepository})
    : _itemsRepository = itemsRepository,
      super(ItemsLoading()) {
    on<LoadItems>(_onLoadItems);
    on<AddItem>(_onAddItem);
    on<DeleteItem>(_onDeleteItem);
    on<_UpdateItems>(_onUpdateItems);
  }

  void _onLoadItems(LoadItems event, Emitter<ItemsState> emit) {
    emit(ItemsLoading());
    _itemsSubscription?.cancel();
    _itemsSubscription = _itemsRepository
        .getItems(isLost: event.isLost)
        .listen(
          (items) => add(_UpdateItems(items)),
          onError: (error) {
            print('⚠️ Items stream error: $error');
            // Emit loaded with empty list instead of crashing
            add(const _UpdateItems([]));
          },
        );
  }

  void _onAddItem(AddItem event, Emitter<ItemsState> emit) async {
    try {
      await _itemsRepository.addItem(event.item, image: event.image);
    } catch (e) {
      print('⚠️ Add item error: $e');
    }
  }

  void _onDeleteItem(DeleteItem event, Emitter<ItemsState> emit) async {
    try {
      await _itemsRepository.deleteItem(event.itemId);
    } catch (e) {
      print('⚠️ Delete item error: $e');
    }
  }

  void _onUpdateItems(_UpdateItems event, Emitter<ItemsState> emit) {
    emit(ItemsLoaded(event.items));
  }

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    return super.close();
  }
}

class _UpdateItems extends ItemsEvent {
  final List<Item> items;

  const _UpdateItems(this.items);

  List<Object> get props => [items];
}
