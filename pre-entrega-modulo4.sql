-- 1. Crear la tabla de categorías

create table categorias (
    id_categoria serial primary key,
    nombre VARCHAR(50) unique not null
);

-- 2. Cargar las categorías iniciales

insert into categorias (nombre)
values
    ('Tecnología'),
    ('Muebles');

-- 3. Agregar la relación entre productos y categorias

alter table productos
add column id_categoria integer;

alter table productos
add constraint fk_productos_categorias
foreign key (id_categoria)
references categorias (id_categoria);

-- 4. Asignar cada producto a su categoría correspondiente

update productos
set id_categoria = categorias.id_categoria
from categorias
where productos.categoria = categorias.nombre;

-- 5. Verificar la relación entre productos y categorías

select
    p.id_producto,
    p.nombre as producto,
    c.nombre as categoria
from productos p
inner join categorias c
    on p.id_categoria = c.id_categoria;

-- 6. Analizar las ventas por categoría de producto
-- Problema de negocio: identificar qué categorías generan mayor facturación.
-- Umbral elegido: mostrar categorías con más de $100.000 de facturación
-- para priorizar las categorías con mayor aporte al negocio.

select
    c.nombre as categoria,
    sum(v.cantidad) as unidades_vendidas,
    sum(v.cantidad * v.precio_unitario) as facturacion_total
from ventas v
inner join productos p
    on v.id_producto = p.id_producto
inner join categorias c
    on p.id_categoria = c.id_categoria
group by c.nombre
having sum(v.cantidad * v.precio_unitario) > 100000
order by facturacion_total desc;

-- 7. Identificar clientes sin compras
-- Problema de negocio: detectar clientes registrados que todavía no compraron.
-- Se utiliza LEFT JOIN para conservar todos los clientes y COALESCE
-- para mostrar cero cuando no tienen ventas asociadas.

select
    c.id_cliente,
    c.nombre as cliente,
    coalesce(count(v.id_venta), 0) as cantidad_compras
from clientes c
left join ventas v
    on c.id_cliente = v.id_cliente
group by c.id_cliente, c.nombre
having count(v.id_venta) = 0
order by c.nombre;

-- 8. Identificar el producto más comprado por cada cliente
-- Problema de negocio: conocer las preferencias de compra de los clientes
-- y la fecha de la última transacción del producto más comprado.

with compras_por_producto as (
    select
        c.id_cliente,
        c.nombre as cliente,
        p.nombre as producto,
        sum(v.cantidad) as unidades_compradas,
        max(v.fecha_venta) as ultima_compra
    from clientes c
    inner join ventas v
        on c.id_cliente = v.id_cliente
    inner join productos p
        on v.id_producto = p.id_producto
    group by c.id_cliente, c.nombre, p.id_producto, p.nombre
),
productos_ordenados as (
    select
        cliente,
        producto,
        unidades_compradas,
        ultima_compra,
        row_number() over (
            partition by id_cliente
            order by unidades_compradas desc, ultima_compra desc
        ) as posicion
    from compras_por_producto
)
select
    cliente,
    producto,
    unidades_compradas,
    ultima_compra
from productos_ordenados
where posicion = 1
order by cliente;