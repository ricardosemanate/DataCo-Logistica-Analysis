import pandas as pd 
import matplotlib.pyplot as plt
import numpy as np 

df = pd.read_csv('DataCoSupplyChainDataset.csv', encoding='latin1')
df_logistica = df[['Days for shipment (scheduled)', 'Days for shipping (real)']].copy()
df_logistica.columns = ['dias_programados', 'dias_reales']

reporte_final = df_logistica.groupby('dias_programados')['dias_reales'].mean().reset_index()
reporte_final.columns = ['dias_programados', 'promedio_dias_reales']

plt.figure(figsize=(9,5))
posiciones= np.arange(len(reporte_final['dias_programados']))
ancho_barra = 0.35

plt.bar(posiciones - ancho_barra/2, reporte_final['dias_programados'], width=ancho_barra, label='Días Programados', color='#B0BEC5')
plt.bar(posiciones + ancho_barra/2, reporte_final['promedio_dias_reales'], width=ancho_barra, label= 'Promedio Días Reales', color='#1A237E')

plt.title('Promesa comercial VS realidad logística', fontsize=14, pad=15)
plt.xlabel('Promesa del sistema de ventas', fontsize=11)
plt.ylabel('Cantidad de días', fontsize=11)

plt.gca().spines['top'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.legend()

plt.xticks(posiciones, ['0 Días', '1 Días', '2 Días', '4 Días'])

plt.show()

#Cuando el sistema comercial se quiere ver estricto y promete entregar en un día, el camión tarda dos, cuando promete dos días, el 
#camión tarda cuatro, una catástrofe en servicio al cliente, no es solo un retraso de un par de horas, es el doble de lo pactado según 
#la gráfica, como consecuencia destruye la confianza del cliente.
#Sugiero un análisis más riguroso en cuanto a tipos de producto, no es lo mismo mover un cargador de celular a mover diez neveras
# industriales, el volumen, el peso y la categorización del producto cambian por completo los tiempos de despacho, una vez se haya
# hecho el análisis debemos dar un par de días más de colchón para prevenir eventos imprevistos, como trancones, accidentes 
# entre otros. De esta manera podremos disminuir las llegadas tardes y darle la mejor atención al cliente. 

