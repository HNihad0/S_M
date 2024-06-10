const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

const config = {
  user: 'sa',
  password: 'soffen2024',
  server: 'DESKTOP-U20V4CP',
  database: 'anbar_db',
  options: {
    encrypt: true,
    trustServerCertificate: true
  }
};

async function connectDB() {
  try {
    await sql.connect(config);
    console.log('MSSQL veritabanına bağlandı.');
  } catch (err) {
    console.error('MSSQL veritabanına bağlanırken hata oluştu:', err);
  }
}

app.get('/api/kas_hes', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Kas_Hes_query = `
      SELECT 
        CASE 
          WHEN ISNULL(rn, 0) = 0 
          THEN CAST(DENSE_RANK() OVER (ORDER BY kassa) AS nvarchar(20)) + '.' + CAST((ROW_NUMBER() OVER (PARTITION BY kassa ORDER BY sira, kassa_name) - 1) AS nvarchar(20))
          WHEN ISNULL(rn, 0) != 0 
          THEN CAST(rn AS nvarchar(20))
        END AS idn,
        kassa, kassa_name, ilkqal, medmiq, mexmiq, sonqal
      FROM (
        SELECT 
          ROW_NUMBER() OVER (ORDER BY t2.kassa) rn, 
          t2.kassa, 
          t2.kassa_name,
          SUM(CASE WHEN t2.tarix < @start THEN t2.nov * t2.mebleg END) ilkqal,
          SUM(CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg END) medmiq,
          SUM(CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg END) mexmiq,
          SUM(t2.nov * t2.mebleg) sonqal, 
          1 AS xus, 
          1 AS sira
        FROM hes_kas_emel_v t2
        WHERE t2.tarix <= @end
        AND (t2.kassa IN (SELECT kassa FROM istifadeci_kassa WHERE fk = @USER) OR 1 = (SELECT all_kassa FROM istifadeci WHERE idn = @USER))
        GROUP BY t2.kassa, t2.kassa_name
      ) t
    `;

    const resultSet = await request.query(Kas_Hes_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});

app.get('/api/emekdas-dovriyyesi', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Emek_Dov_query = `
      SELECT 
        CASE 
          WHEN ISNULL(rn, 0) = 0 
          THEN CAST(DENSE_RANK() OVER (ORDER BY kontra) AS nvarchar(20)) + '.' + CAST((ROW_NUMBER() OVER (PARTITION BY kontra ORDER BY sira, kontra_name) - 1) AS nvarchar(20))
          WHEN ISNULL(rn, 0) != 0 
          THEN CAST(rn AS nvarchar(20))
        END AS idn, 
        kontra, 
        kontra_name, 
        ilkqal, 
        medmiq, 
        mexmiq, 
        sonqal, 
        qeyd, 
        xus, 
        medmiq/2 AS summedmiq, 
        mexmiq/2 AS summexmiq 
      FROM (
        SELECT 
          ROW_NUMBER() OVER(ORDER BY t2.kontra) rn, 
          t2.kontra, 
          t2.kontra_name, 
          SUM(CASE WHEN t2.tarix < @start THEN t2.nov * t2.mebleg END) ilkqal, 
          SUM(CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg END) medmiq, 
          SUM(CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg END) mexmiq, 
          SUM(t2.nov * t2.mebleg) sonqal, 
          NULL AS qeyd, 
          '#AEAEAE' AS xus, 
          1 AS sira 
        FROM hes_maas_emel_v t2, emekdas t1 
        WHERE t1.idn = t2.kontra AND t2.tarix <= @end 
        GROUP BY t2.kontra, t2.kontra_name
        UNION ALL 
        SELECT 
          NULL, 
          t2.kontra, 
          CONVERT(nvarchar, t2.tarix, 102) + ' - ' + t2.emel_name + ' - ' + t2.sen_no, 
          NULL, 
          CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg ELSE NULL END AS medmiq, 
          CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg ELSE NULL END AS mexmiq, 
          NULL, 
          t2.qeyd, 
          'white' AS xus, 
          11 AS sira 
        FROM hes_maas_emel_v t2, emekdas t1 
        WHERE t1.idn = t2.kontra AND t2.tarix BETWEEN @start AND @end
      ) t
    `;

    const resultSet = await request.query(Emek_Dov_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});


app.get('/api/cari_hes', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Cari_Hes_query = `
    SELECT case when isnull(rn,0)=0 then cast(DENSE_RANK() OVER (order by kontra) as nvarchar(20))+ '.' +cast((ROW_NUMBER() OVER( Partition by kontra ORDER BY sira)-1) as nvarchar(20))
     when isnull(rn,0)!=0 then cast(rn as nvarchar(20))
     end idn, 
kontra, kontra_name, case when sonqal<0 then -1*sonqal end ilkqal,  case when sonqal>0 then sonqal end  sonqal  from
 (
select ROW_NUMBER() OVER(ORDER BY t2.kontra) rn, t2.kontra, t2.kontra_name, 
sum(t2.nov*t2.yekun) sonqal,1 xus , 1 sira

from hes_kontra_emel_v t2, kontragent t1

 WHERE t1.idn=t2.kontra  and t2.tarix<=@end

GROUP BY t2.kontra, t2.kontra_name
)t
    `;

    const resultSet = await request.query(Cari_Hes_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});

app.get('/api/kas_dov', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Kas_Dov_query = `SELECT CASE WHEN ISNULL(rn, 0) = 0 
    THEN CAST(DENSE_RANK() OVER (ORDER BY kassa) AS nvarchar(20)) + '.' + CAST((ROW_NUMBER() OVER (PARTITION BY kassa ORDER BY sira, kassa_name) - 1) AS nvarchar(20)) 
    WHEN ISNULL(rn, 0) != 0 
    THEN CAST(rn AS nvarchar(20)) 
    END AS idn, 
    kassa, kassa_name, ilkqal, medmiq, mexmiq, medmiq * vur AS summedmiq, mexmiq * vur AS summexmiq, sonqal, xus
    FROM (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY t2.kassa) AS rn, 
            t2.kassa, 
            t2.kassa_name, 
            SUM(CASE WHEN t2.tarix < @start THEN t2.nov * t2.mebleg END) AS ilkqal, 
            SUM(CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg END) AS medmiq, 
            SUM(CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg END) AS mexmiq, 
            SUM(t2.nov * t2.mebleg) AS sonqal, 
            '#AEAEAE' AS xus, 
            1 AS sira, 
            1 AS vur 
        FROM hes_kas_emel_v t2
        WHERE t2.tarix <= @end 
        AND (t2.kassa IN (SELECT kassa FROM istifadeci_kassa WHERE fk = @USER) OR 1 = (SELECT all_kassa FROM istifadeci WHERE idn = @USER)) 
        GROUP BY t2.kassa, t2.kassa_name

        UNION ALL

        SELECT 
            NULL, 
            t2.kassa, 
            CONVERT(nvarchar, t2.tarix, 102) + ' - ' + t2.emel_name + ' - ' + t2.sen_no + ' - ' + t2.kontra_name, 
            NULL, 
            CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg ELSE NULL END, 
            CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.mebleg ELSE NULL END, 
            NULL, 
            'white' AS xus, 
            11 AS sira, 
            0 AS vur 
        FROM hes_kas_emel_v t2
        WHERE t2.tarix BETWEEN @start AND @end 
        AND (t2.kassa IN (SELECT kassa FROM istifadeci_kassa WHERE fk = @USER) OR 1 = (SELECT all_kassa FROM istifadeci WHERE idn = @USER))
    ) t
    `;

    const resultSet = await request.query(Kas_Dov_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});

app.get('/api/cari_hes_dov', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Cari_Hes_query = `SELECT rn idn,
    kontra, kontra_name, ilkqal, mexmiq bizimborc, medmiq bizeborc, mexmiq*vur sumbizimborc, medmiq*vur sumbizeborc, sonqal, qeyd, xus, tip
FROM (
 SELECT ROW_NUMBER() OVER(ORDER BY t2.kontra) rn, 
        t2.kontra, 
        t2.kontra_name, 
        SUM(CASE WHEN t2.tarix < @start THEN t2.nov * t2.yekun END) ilkqal, 
        SUM(CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.yekun END) medmiq, 
        SUM(CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.yekun END) mexmiq, 
        SUM(t2.nov * t2.yekun) sonqal,
        NULL qeyd,
        '#AEAEAE' xus, 
        1 sira, 
        1 vur,
        CASE WHEN SUM(t2.nov * t2.yekun) = 0 THEN NULL 
             WHEN SUM(t2.nov * t2.yekun) > 0 THEN N'ALINACAQ' 
             ELSE N'VERILECEK' 
        END tip
 FROM kontragent t1,
      hes_kontra_emel_v t2
 WHERE t1.idn = t2.kontra 
       AND t2.tarix <= @end 
 GROUP BY t2.kontra, t2.kontra_name
 UNION ALL
 SELECT NULL,
        t2.kontra, 
        SPACE(5) + CONVERT(NVARCHAR, t2.tarix, 102) + ' - ' + t2.emel_name + ' - ' + t2.sen_no,
        NULL,
        CASE WHEN t2.nov = 1 AND t2.tarix BETWEEN @start AND @end THEN t2.yekun ELSE NULL END medmiq,
        CASE WHEN t2.nov = -1 AND t2.tarix BETWEEN @start AND @end THEN t2.yekun ELSE NULL END mexmiq,
        NULL,
        t2.qeyd,
        'white' xus, 
        11 sira,
        0 vur, 
        NULL
 FROM kontragent t1,
      hes_kontra_emel_v t2
 WHERE t1.idn = t2.kontra 
       AND t2.tarix BETWEEN @start AND @end 
) t
ORDER BY kontra, sira;

    `;

    const resultSet = await request.query(Cari_Hes_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});

app.get('/api/xerc_hes', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Xerc_Hes_query = `SELECT  adi, qeyd, mebleg, mebleg*vur summebleg, xus, layihe
    from (
    
    select 
    t3.idn qrup,0 xerc,t3.adi, null qeyd,null layihe, 
    SUM(mebleg) mebleg,
    
    1 sira, '#AEAEAE' xus,1 vur
    
    from kas_mex t1
    , xerc t2, xerc_qrup t3
    WHERE t1.nov=2 and t1.kontra=t2.idn and t2.qrup=t3.idn and tarix between @start and @end
    
    AND  (kassa in (SELECT kassa FROM istifadeci_kassa where fk=@USER) or 1=(SELECT all_kassa from istifadeci where idn=@USER)) 
    GROUP BY t3.idn,t3.adi
    UNION ALL
    select 
    t3.idn qrup,t2.idn xerc,t2.adi, null qeyd, null layihe, SUM(
    mebleg) mebleg,
    
    11 sira, '#E5E4E2' xus, 0 vur
    
    from kas_mex t1
    , xerc t2, xerc_qrup t3
    WHERE t1.nov=2 and t1.kontra=t2.idn and t2.qrup=t3.idn and tarix between @start and @end
    
    
    AND  (kassa in (SELECT kassa FROM istifadeci_kassa where fk=@USER) or 1=(SELECT all_kassa from istifadeci where idn=@USER)) 
    GROUP BY t3.idn,t2.idn ,t2.adi
    UNION ALL
    select 
    t3.idn qrup,t2.idn xerc,CONVERT(nvarchar(20),t1.tarix,104)+' - '+t1.sen_no, ISNULL(qeyd,'') qeyd, ISNULL((select adi from layihe where idn=t1.layihe),'') layihe, mebleg,
    
    111 sira, null xus, 0 vur
    
    from kas_mex t1
    , xerc t2, xerc_qrup t3
    WHERE t1.nov=2 and t1.kontra=t2.idn and t2.qrup=t3.idn and tarix between @start and @end
    
     
    AND  (kassa in (SELECT kassa FROM istifadeci_kassa where fk=@USER) or 1=(SELECT all_kassa from istifadeci where idn=@USER))
    )t
    order by qrup, xerc, sira, adi
    `;

    const resultSet = await request.query(Xerc_Hes_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});

app.get('/api/gelir_hes', async (req, res) => {
  const { start, end, user } = req.query;

  const today = new Date();
  const startDate = start ? new Date(start) : today;
  const endDate = end ? new Date(end) : today;

  if (!user) {
    return res.status(400).send('User parametresi gereklidir.');
  }

  if (startDate > endDate) {
    return res.status(400).send('Başlama tarihi bitiş tarihinden önce olmalıdır.');
  }

  try {
    const request = new sql.Request();
    request.input('start', sql.DateTime, startDate);
    request.input('end', sql.DateTime, endDate);
    request.input('USER', sql.Int, parseInt(user));

    const Gelir_Hes_query = `SELECT anb_qal,kas_qal,kontr_qalbizim,kontr_qalbize, anb_med, 
    anb_mex, kas_med, al_meb,sat_meb, xerc, xerckontra,
   anb_qal+kas_qal-kontr_qalbizim-kontr_qalbize durum, sat_meb-al_meb qazanc FROM 
  
  (
  SELECT 
  
  (SELECT SUM(mebleg) from (
  SELECT SUM(t1.nov*t1.miqdar)*t2.alis mebleg from hes_mal_emel_v t1, mallar t2
  where t1.mal=t2.idn and tarix<= @end
  group by t2.idn, t2.alis
  )t ) anb_qal,
  (select sum(nov*mebleg)              from hes_kas_emel_v      where tarix<= @end) kas_qal,
  (SELECT SUM(meb) from (select sum(nov*mebleg) meb from hes_kontra_emel_v    where tarix<= @end group by kontra having sum(nov*mebleg)<0) t) kontr_qalbize,
  (SELECT SUM(meb) from (select sum(nov*mebleg) meb from hes_kontra_emel_v    where tarix<= @end group by kontra having sum(nov*mebleg)>0) t) kontr_qalbizim,
  (select sum(yekun)                   from anb_med          where tarix between @start and @end) anb_med,
  (select sum(yekun)                   from anb_geri          where tarix between @start and @end) anb_mex,
  (select sum(mebleg)                  from kas_med          where tarix between @start and @end and nov =2) kas_med,
  (select sum(nov*al_meb_yekun)        from hes_sat_emel_v t1, mallar t2 
    where t1.mal=t2.idn and tarix between @start and @end) al_meb,
  (select sum(nov*sat_meb_yekun)       from hes_sat_emel_v t1, mallar t2 
    where t1.mal=t2.idn and tarix between @start and @end) sat_meb,
  (select sum(mebleg)                  from kas_mex          where tarix between @start and @end and nov in (1,2)) xerc,
  --(select sum(nov*mebleg) from emekdas_qal    where tarix<= @end)
  0 xerckontra
  ) t
    `;

    const resultSet = await request.query(Gelir_Hes_query);
    res.json(resultSet.recordset);
  } catch (err) {
    console.error('Veri çekilirken hata oluştu:', err);
    res.status(500).send('Sunucu hatası');
  }
});


app.listen(port, () => {
  console.log(`Sunucu ${port} numaralı portta çalışıyor.`);
  connectDB();
});
