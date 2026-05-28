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