class Adicion {
  final int idAdicion;
  final String nombre;
  final double precio;
  final int stockActual;
  final String tipo;
  final String imagen;

  Adicion({
    required this.idAdicion,
    required this.nombre,
    required this.precio,
    required this.stockActual,
    required this.tipo,
    required this.imagen,
  });
}

class Product {
  final int id;
  final String nombre;
  final double precio;
  final String categoria;
  final String imagen;
  final int stockActual;
  final String descripcion;

  Product({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.imagen,
    required this.stockActual,
    required this.descripcion,
  });
}

final List<Adicion> adicionesDisponibles = [
  Adicion(idAdicion: 1, nombre: 'Salsa BBQ', precio: 1000, stockActual: 50, tipo: 'Salsa', imagen: '🥫'),
  Adicion(idAdicion: 2, nombre: 'Salsa de Ajo', precio: 1000, stockActual: 45, tipo: 'Salsa', imagen: '🧄'),
  Adicion(idAdicion: 3, nombre: 'Salsa Picante', precio: 1000, stockActual: 40, tipo: 'Salsa', imagen: '🌶️'),
  Adicion(idAdicion: 4, nombre: 'Queso Extra', precio: 2000, stockActual: 30, tipo: 'Ingrediente', imagen: '🧀'),
  Adicion(idAdicion: 5, nombre: 'Tocineta', precio: 3000, stockActual: 25, tipo: 'Ingrediente', imagen: '🥓'),
  Adicion(idAdicion: 6, nombre: 'Papas Fritas', precio: 5000, stockActual: 35, tipo: 'Acompañamiento', imagen: '🍟'),
  Adicion(idAdicion: 7, nombre: 'Coca Cola', precio: 3000, stockActual: 60, tipo: 'Bebida', imagen: '🥤'),
  Adicion(idAdicion: 8, nombre: 'Sprite', precio: 3000, stockActual: 55, tipo: 'Bebida', imagen: '🥤'),
  Adicion(idAdicion: 9, nombre: 'Jugo de Naranja', precio: 4000, stockActual: 20, tipo: 'Bebida', imagen: '🧃'),
];

final List<Product> productosDisponibles = [
  Product(
    id: 1,
    nombre: 'Hamburguesa Especial',
    precio: 15000,
    categoria: 'Hamburguesas',
    imagen: '🍔',
    stockActual: 25,
    descripcion: 'Hamburguesa con doble carne, queso, lechuga y tomate',
  ),
  Product(
    id: 2,
    nombre: 'Salchipapa Grande',
    precio: 12000,
    categoria: 'Salchipapas',
    imagen: '🍟',
    stockActual: 30,
    descripcion: 'Papas fritas con salchicha y salsas',
  ),
  Product(
    id: 3,
    nombre: 'Perro Caliente',
    precio: 10000,
    categoria: 'Perros',
    imagen: '🌭',
    stockActual: 20,
    descripcion: 'Hot dog con salsas y papa chip',
  ),
  Product(
    id: 4,
    nombre: 'Pollo Broaster',
    precio: 18000,
    categoria: 'Pollo',
    imagen: '🍗',
    stockActual: 15,
    descripcion: 'Porción de pollo broaster con papas',
  ),
  Product(
    id: 5,
    nombre: 'Papas Fritas',
    precio: 6000,
    categoria: 'Acompañamientos',
    imagen: '🍟',
    stockActual: 40,
    descripcion: 'Papas fritas crujientes',
  ),
  Product(
    id: 6,
    nombre: 'Coca Cola',
    precio: 3000,
    categoria: 'Bebidas',
    imagen: '🥤',
    stockActual: 60,
    descripcion: 'Gaseosa Coca Cola 350ml',
  ),
  Product(
    id: 7,
    nombre: 'Combo Familiar',
    precio: 45000,
    categoria: 'Combos',
    imagen: '🍱',
    stockActual: 12,
    descripcion: '2 hamburguesas, salchipapa y bebidas',
  ),
  Product(
    id: 8,
    nombre: 'Arepa con Queso',
    precio: 8000,
    categoria: 'Acompañamientos',
    imagen: '🫓',
    stockActual: 18,
    descripcion: 'Arepa rellena de queso',
  ),
];
