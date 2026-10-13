import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../cart/cart_bloc.dart';
import '../profile/favorites_cubit.dart';
import 'menu_cubit.dart';
import 'menu_models.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cart) => IconButton(
              tooltip: 'Open cart, ${cart.count} items',
              onPressed: () => context.push('/cart'),
              icon: Badge(
                isLabelVisible: cart.count > 0,
                label: Text('${cart.count}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<MenuCubit, MenuState>(
        builder: (context, menu) {
          if (menu.loading) return const Center(child: CircularProgressIndicator());
          if (menu.error != null) return Center(child: Text(menu.error!));

          final favorites = context.watch<FavoritesCubit>().state;
          var items = menu.visibleItems;
          if (_favoritesOnly) items = items.where((i) => favorites.contains(i.id)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: context.read<MenuCubit>().setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search dishes',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip('All', menu.categoryId == null,
                        () => context.read<MenuCubit>().selectCategory(null)),
                    for (final c in menu.categories)
                      _chip(c.name, menu.categoryId == c.id,
                          () => context.read<MenuCubit>().selectCategory(c.id)),
                    _chip('Fasting \u133e\u121d', menu.fastingOnly,
                        context.read<MenuCubit>().toggleFasting),
                    _chip('Favorites', _favoritesOnly,
                        () => setState(() => _favoritesOnly = !_favoritesOnly)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No dishes found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _MenuItemTile(
                          item: items[i],
                          isFavorite: favorites.contains(items[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item, required this.isFavorite});

  final MenuItem item;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 88,
                height: 88,
                child: item.imageUrl == null
                    ? ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.restaurant),
                      )
                    : CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        placeholder: (_, __) => ColoredBox(color: scheme.surfaceContainerHighest),
                        errorWidget: (_, __, ___) => const Icon(Icons.restaurant),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(etb(item.priceEtb),
                          style: text.titleSmall?.copyWith(color: scheme.primary)),
                      if (item.isFasting) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Fasting'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: isFavorite ? 'Remove ${item.name} from favorites' : 'Favorite ${item.name}',
                  onPressed: () => context.read<FavoritesCubit>().toggle(item.id),
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? scheme.primary : null),
                ),
                item.isAvailable
                    ? IconButton.filled(
                        tooltip: 'Add ${item.name} to cart',
                        onPressed: () => context.read<CartBloc>().add(CartItemAdded(item)),
                        icon: const Icon(Icons.add),
                      )
                    : Text('Sold out', style: text.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
