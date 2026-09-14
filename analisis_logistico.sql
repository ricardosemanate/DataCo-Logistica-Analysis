SELECT COUNT(*) FROM DataCoSupplyChainDataset;
SELECT * FROM DataCoSupplyChainDataset LIMIT 10;

DROP VIEW IF EXISTS reporte_entregas;

CREATE VIEW reporte_entregas AS
SELECT 
	c1 as tipo_pago,
    c2 as dias_reales,
    c3 as dias_programados,
    (c2 - c3) as diferencia_dias,
    c4 as beneficio,
    c6 as estado_entrega,
    c9 AS categoria_producto,
    c41 as region_pedido
FROM DataCoSupplyChainDataset
WHERE c1 != 'Type';

SELECT tipo_pago, dias_reales, dias_programados, diferencia_dias from reporte_entregas limit 5;

SELECT COUNT(*) AS total_retrasos
FROM reporte_entregas
WHERE diferencia_dias > 0;

SELECT COUNT(*) AS a_tiempo
FROM reporte_entregas
WHERE diferencia_dias = 0;

SELECT COUNT(*) AS adelantados
FROM reporte_entregas 
WHERE diferencia_dias < 0;

/* 
Más de la mitad de los pedidos llegan tarde, este es el problema principal que la empresa debe resolver, solo dos de cada 10 pedidos 
llegan el día exacto prometido, y tenemos como inconsistencia que hay más pedidos adelantados que pedidos a tiempo, esto nos dice que 
la empresa podría no tener control sobre sus tiempos.
*/ 

/* vamos a ver que método de pago es el más utilizado */ 
SELECT tipo_pago, COUNT(*) AS total_pedidos
FROM reporte_entregas
GROUP BY tipo_pago;

/*
Cash: 19.616 pedidos
Debit: 69.295 pedidos (el más utilizado)
Payment: 41.725 pedidos
Transfer: 49.883 pedidos

Con esto sabemos que el pago en debito es el preferido de los clientes, pero sabemos que la empresa tiene 103.400 retrasos en total, 
es imposible que todos los retrasos sean de la categoría Debit, el problema de la impuntualidad está repartida. 
Vamos a buscar el verdadero culpable: de los pedidos que llegaron tarde, ¿Cuántos pertenecen a cada tipo de pago?
*/ 

SELECT tipo_pago, COUNT(*) AS total_pedidos
FROM reporte_entregas
WHERE diferencia_dias > 0
GROUP BY tipo_pago;

/*
cash: 11.109 retrasos
debit: 39.649 retrasos
payment: 24.004 retrasos
transfer: 28.638 retrasos 
ahora para no confundirnos vamos a mirar el porcentaje de error, es decir la proporción, vamos a comparar el número de pedidos con 
retrasos con el total de pedidos para ver cuál es el porcentaje de las llegadas tardes por cada método de pago. 
*/ 

SELECT
    tipo_pago, 
    SUM(CASE WHEN diferencia_dias > 0 THEN 1 ELSE 0 END) AS retrasos,
    COUNT(*) AS total_pedidos,
    ROUND((SUM(CASE WHEN diferencia_dias > 0 THEN 1.0 ELSE 0.0 END) / COUNT(*)) * 100, 2) AS porcentaje_retraso
FROM reporte_entregas
GROUP BY tipo_pago;
/*
cash: 56.6%
debit: 57.2%
payment: 57.5%
transfer: 57.4% 
notamos que, sin importar el método de pago, siempre se retrasa cerca del 57% de los envíos, ¿Qué podemos concluir de esto?; a nivel 
negocio podemos decir que el problema no tiene nada que ver con los métodos de pago ni con los bancos, no es que las transacciones tarden
 en aprobarse o que el efectivo ralentice el proceso. El problema viene siendo logístico, operativo o de los camiones de reparto. 
*/ 

/*
Actualización de la vista reporte_entregas para incluir datos geográficos y hacer análisis como un posible sospechoso a la problemática.  
*/ 
SELECT 
	region_pedido,
    SUM(CASE WHEN diferncia_dias > 0 THEN 1 else 0 end) as retrasos,
    COUNT(*) AS total_pedidos,
    ROUND((SUM(CASE WHEN diferencias_dias >  0 THEN 1.0 ELSE 0.0 END) / COUNT(*)) * 100, 2) AS porcentaje_retraso
FROM reporte_entregas
GROUP BY region_pedido
ORDER BY porcentaje_retraso DESC;

/*
Al ver los resultados vemos que África Central es líder en retrasos con un 60.7% tenemos otras partes con resultados que van 
desde 57.9% hasta 58.5% y en último lugar con menos retrasos esta Canadá con 51.9%, un resultado un poco preocupante, como conclusión 
tenemos que más del 50% de entregas están retrasadas en todas las regiones, esto nos dice que la geografía no es la causa de nuestra 
problemática. Podemos intuir que el problema es sistemático. 
*/ 

/*
Nos enfocaremos en la categoría de producto, vamos a buscar si hay algún tipo de mercancía que se retrase más 
que los demás (como: tecnología, ropa, comida). 
*/ 
SELECT 	
	categoria_producto,
    SUM(CASE WHEN diferencia_dias > 0 THEN 1 ELSE 0 END) AS retrasos,
    COUNT(*) AS total_pedidos, 
    ROUND((SUM(CASE WHEN diferencia_dias > 0 THEN 1.0 ELSE 0.0 END) / COUNT(*)) * 100, 2) AS porcentaje_retraso
FROm reporte_entregas
GROUP BY categoria_producto
ORDER by porcentaje_retraso DESC;

/*
Como podemos ver la categoría que más tiene un porcentaje de retraso es Golf Bags & Carts porque tiene casi un 69% de  
retraso, sin embargo, solo tiene 61 pedidos en total, al ser pedidos tan pequeños cualquier entrega que se retrase mueve el porcentaje
 con fuerza.
En cambio, si miramos las categorías que tienen pedidos masivos como Cleats con más de 24.000 pedidos o Cardio Equipment con más 
de 12.000, todas vuelven a tener un promedio de 56% o 57%. ¿Qué podemos deducir de esto? Las categorías de los productos tampoco son 
la causa de la problemática, no importa el tipo de producto la probabilidad de que llegue tarde sigue siendo casi la misma, es decir, más
 de la mitad.   
*/ 

/*
Nos enfocaremos ahora en el área de logística intentando encontrar el posible causante de los retrasos de nuestra empresa. 
*/

/*
Tras realizar una inspección profunda del dataset, identifique que la columna c1no almacena el método de pago como creí 
inicialmente, si no que esta almacena el modo de envió. Para corregir este sesgo y alinear el código al contexto del negocio 
logístico se crea la vista ‘reporte_logistica’ renombrando a c1 como ‘tipo_envio’.  
*/

DROP VIEW IF EXISTS reporte_logistica;
CREATE VIEW reporte_logistica AS 
SELECT 
    c1 AS tipo_envio,
    c2 AS dias_reales,
    c3 AS dias_programados,
    (c2-c3) AS diferencia_dias,
    c4 AS beneficio
    c6 AS estado_entrega
FROM DataCoSupplyChainDataset
WHERE c1 != 'Type'; 

SELECT 
	tipo_envio,
    SUM(CASE WHEN diferencia_dias > 0 THEN 1 ELSE 0 END) AS retrasos,
    COUNT(*) AS total_pedidos,
    ROUND((SUM(CASE WHEN diferencia_dias > 0 THEN 1.0 ELSE 0.0 END) / COUNT(*)) * 100, 2) AS porcentaje_retraso
FROM reporte_logistica
GROUP BY tipo_envio
ORDER BY porcentaje_retraso DESC; 

/*
CONCLUSIÓN: Los resultados de la consulta demuestran de forma contundente que la columna c1 (Type) corresponde de forma estricta 
a los Métodos de Pago (PAYMENT, TRANSFER, DEBIT, CASH). Al flotar todos los indicadores exactamente en el mismo 57% de retrasos, se 
confirma de manera definitiva que la forma en que el cliente paga no influye en la eficiencia de la entrega. El sospechoso financiero 
queda absuelto.
*/

/*
Después de mucho análisis buscando el modo de envió, encontré dos columnas que son clave pero que ignoré por buscar un texto 
explicito, la c2 (días reales que tardo el camión de entrega) y c3 ( días que la empresa le prometió al cliente), al parecer la empresa
programa de forma automática 4 días de promesa, si demora 5 días en la entrega, el sistema lo califica inmediatamente como retraso, el 
problema vendría siendo que la empresa le promete 4 días al cliente sin importar la distancia real o el tipo de producto, lo que nos
dirá que la causa del problema es que la promesa de entrega está mal calculada. 
*/

SELECT 
	dias_programados,
    COUNT(*) AS cantidad_pedidos,
    ROUND(AVG(dias_reales), 2) AS promedio_dias_reales
FROM reporte_entregas
GROUP BY dias_programados
ORDER BY promedio_dias_reales DESC;

/*
La empresa tiene un volumen grande, 107.752 pedidos a los que les promete una entrega en 4 días, y tardan en promedio exactamente los
4 días, acá está el problema, como el promedio real es idéntico al límite, el 50% de los camiones que se retrasen sea por una hora o 
un trancón, van a marcarse como un retraso, no existe margen de error.
A 35.216 pedidos, les prometen entregar en dos y en promedio los camiones se demoran los 4 días (3.99), acá le prometen al cliente la
entrega en dos días, pero operativamente el camión no se puede bajar de los 4 días en promedio de entrega, como resultado tenemos 
un 100% de retrasos en este bloque.
A 27.814 se le promete un día de entrega, pero el camión promedio 2 días, otra promesa imposible de cumplir.  
*/

