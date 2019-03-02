#Область Push

Процедура СформироватьМетрикиРегламентнымЗаданием() Экспорт
	
	ИспользоватьМетодПуш = Константы.пэмИспользоватьPushgateway.Получить();
	
	Если НЕ ИспользоватьМетодПуш Тогда
		Возврат;
	КонецЕсли;
			
	АдресСервера = Константы.пэмАдресСервераPushgateway.Получить();
	ПортСервера = Константы.пэмПортСервераPushgateway.Получить();
	ПутьНаСервере = Константы.пэмПутьНаСервереPushgateway.Получить();
			    			
	Метрики = ПолучитьМетрики(Перечисления.пэмМетодыПолученияМетрик.Push);
	
	HTTPСоединение = Новый HTTPСоединение(АдресСервера, ПортСервера);
	HTTPЗапрос = Новый HTTPЗапрос(ПутьНаСервере);
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "text/plain; version=0.0.4");
		
	HTTPЗапрос.УстановитьТелоИзСтроки(Метрики,КодировкаТекста.UTF8, ИспользованиеByteOrderMark.НеИспользовать);
	
	Результат = HTTPСоединение.ВызватьHTTPМетод("PUT",HTTPЗапрос);
	
	Если Результат.КодСостояния > 300 Тогда
		ЗаписьЖурналаРегистрации("Prometheus data exporter",
		УровеньЖурналаРегистрации.Ошибка,
		,
		,
		"Ошибка отправки метрик. Код ответа Pushgateway: " + Результат.КодСостояния);	
	КонецЕсли; 
	
	
КонецПроцедуры

#КонецОбласти

#Область Pull

Функция СформироватьМетрикиПоЗапросу() Экспорт
	
	Возврат ПолучитьМетрики(Перечисления.пэмМетодыПолученияМетрик.Pull)
	
КонецФункции

#КонецОбласти

#Область Описание_сервиса

Функция ВернутьОписаниеСервиса() Экспорт
	
	Ответ = Новый HTTPСервисОтвет(200);
	
	Ответ.Заголовки.Вставить("Content-Type","text/html;charset=UTF-8");
	Ответ.Заголовки.Вставить("Pragma","no-cache");
	Ответ.Заголовки.Вставить("Cache-Control","no-cache");
	Ответ.Заголовки.Вставить("Cache-Control","no-store");
	Ответ.Заголовки.Вставить("Content-Language","en");

	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	пэмМетрики.Ссылка КАК Ссылка,
	|	пэмМетрики.МетодПолученияМетрики КАК МетодПолученияМетрики,
	|	пэмМетрики.Активность КАК Активность
	|ПОМЕСТИТЬ втСправочникМетрик
	|ИЗ
	|	Справочник.пэмМетрики КАК пэмМетрики
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	втСправочникМетрик.МетодПолученияМетрики КАК Type,
	|	""Active"" КАК State,
	|	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ втСправочникМетрик.Ссылка) КАК Count
	|ИЗ
	|	втСправочникМетрик КАК втСправочникМетрик
	|ГДЕ
	|	втСправочникМетрик.Активность = ИСТИНА
	|
	|СГРУППИРОВАТЬ ПО
	|	втСправочникМетрик.МетодПолученияМетрики
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	втСправочникМетрик.МетодПолученияМетрики,
	|	""Inactive"",
	|	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ втСправочникМетрик.Ссылка)
	|ИЗ
	|	втСправочникМетрик КАК втСправочникМетрик
	|ГДЕ
	|	втСправочникМетрик.Активность = ЛОЖЬ
	|
	|СГРУППИРОВАТЬ ПО
	|	втСправочникМетрик.МетодПолученияМетрики";
	Результат = Запрос.Выполнить().Выгрузить();

	СтрокаHTML =
	"<p><h1>Prometheus data exporter</h1></p>
	|%1
	|<p>&nbsp;</p>";
	
	Если Результат.Количество() Тогда
		Данные =
		"<h2>Metrics information:</h2>
		|<table border=""1"" cellpadding=""2"" cellspacing=""0"" >
		|<tbody>
		|	<tr>";
		Для Каждого Колонка Из Результат.Колонки Цикл
			Данные = Данные + Символы.ПС + "<td><h4>" + Колонка.Заголовок + "</h4></td>";
		КонецЦикла;
		Данные = Данные + Символы.ПС + "</tr>";
		Для Каждого Строка Из Результат Цикл
			Данные = Данные + Символы.ПС + "<tr>";
			Для Каждого КолонкаСтроки Из Строка Цикл
				Данные = Данные + Символы.ПС + "<td>" + КолонкаСтроки + "</td>";
			КонецЦикла;
			Данные = Данные + Символы.ПС + "</tr>";
		КонецЦикла;
		Данные = Данные + "
		|</tbody>
		|</table>";
	Иначе
		Данные = "<p><h2>Metrics is not set yet</h2></p>";
	КонецЕсли;
	
	СтрокаHTML = СтрЗаменить(СтрокаHTML,"%1",Данные);
	
	Ответ.УстановитьТелоИзСтроки(СтрокаHTML);
	
	Возврат Ответ;
	
КонецФункции

#КонецОбласти

#Область Формирование_метрик 

Функция ПолучитьМетрики(МетодПолученияМетрики) Экспорт
	
	Метрики = "";
	Асинхронно = Константы.пэмМногопоточныйРасчетМетрик.Получить();
				
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	пэмМетрики.Код КАК ИмяМетрики,
	|	пэмМетрики.Алгоритм КАК Алгоритм,
	|	пэмМетрики.ТипМетрики КАК ТипМетрики,
	|	пэмМетрики.Ссылка КАК Метрика,
	|	ВЫБОР
	|		КОГДА пэмСостояниеМетрик.ДатаРасчета ЕСТЬ NULL
	|			ТОГДА ИСТИНА
	|		ИНАЧЕ ВЫБОР
	|			КОГДА РАЗНОСТЬДАТ(пэмСостояниеМетрик.ДатаРасчета, ДОБАВИТЬКДАТЕ(&ТекущаяДата, СЕКУНДА,
	|				-пэмМетрики.ПериодичностьРасчета), СЕКУНДА) > 0
	|				ТОГДА ИСТИНА
	|			ИНАЧЕ ЛОЖЬ
	|		КОНЕЦ
	|	КОНЕЦ КАК Расчитывать
	|ИЗ
	|	Справочник.пэмМетрики КАК пэмМетрики
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.пэмСостояниеМетрик КАК пэмСостояниеМетрик
	|		ПО (пэмСостояниеМетрик.Метрика = пэмМетрики.Ссылка)
	|ГДЕ
	|	пэмМетрики.МетодПолученияМетрики = &МетодПолученияМетрики
	|	И пэмМетрики.Активность = ИСТИНА
	|УПОРЯДОЧИТЬ ПО
	|	пэмМетрики.Предопределенный УБЫВ,
	|	пэмМетрики.Код";
	Запрос.УстановитьПараметр("МетодПолученияМетрики",МетодПолученияМетрики);
	Запрос.УстановитьПараметр("ТекущаяДата",ТекущаяДата());
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Асинхронно Тогда
		Метрики = СформироватьМетрикиАсинхронно(Выборка, МетодПолученияМетрики)
	Иначе
		Метрики = СформироватьМетрикиСинхронно(Выборка, МетодПолученияМетрики)
	КонецЕсли;
	
	Возврат Метрики;
		
КонецФункции

Функция СформироватьМетрикиАсинхронно(Выборка, МетодПолученияМетрики)
	
	МетрикиСтрокой = "";	
	МассивФоновыхЗаданий = Новый Массив;
	МассивПараметров = Новый Массив;
		
	//старт расчета
	Пока Выборка.Следующий() Цикл
		
		Если НЕ Выборка.Расчитывать Тогда
			Продолжить;
		КонецЕсли;
		
		УникальныйИдентификатор = Новый УникальныйИдентификатор;
		АдресВХранилище = ПоместитьВоВременноеХранилище("",УникальныйИдентификатор);
		
		МассивПараметров.Очистить();
		МассивПараметров.Добавить(Выборка.ИмяМетрики);
		МассивПараметров.Добавить(Выборка.ТипМетрики);
		МассивПараметров.Добавить(Выборка.Алгоритм);
		МассивПараметров.Добавить(АдресВХранилище);
		МассивПараметров.Добавить(Выборка.Метрика);
		
		ФоновоеЗадание = ФоновыеЗадания.Выполнить("пэмМетрикиСервер.СформироватьМетрикуФоновымЗаданием",МассивПараметров,АдресВХранилище);
		МассивФоновыхЗаданий.Добавить(ФоновоеЗадание);
	КонецЦикла;
	
	Если НЕ МассивФоновыхЗаданий.Количество() Тогда
		Возврат МетрикиСтрокой;
	КонецЕсли;
	
	//Ожидание окончания расчета всех метрик
	МассивЗаданийКУдалению = Новый Массив;	
	Пока Истина Цикл
		
		Пауза(1);
		МассивЗаданийКУдалению.Очистить();
		Для Каждого ФоновоеЗадание Из МассивФоновыхЗаданий Цикл
			
			Если ФоновыеЗадания.НайтиПоУникальномуИдентификатору(ФоновоеЗадание.УникальныйИдентификатор).Состояние = СостояниеФоновогоЗадания.Активно Тогда
				Продолжить;
			Конецесли;
			
			Попытка
				сткВозврат = ПолучитьИзВременногоХранилища(ФоновоеЗадание.Ключ);
				Если НЕ сткВозврат.Ошибка Тогда
					МетрикиСтрокой = МетрикиСтрокой + сткВозврат.МетрикаСтрокой;
				КонецЕсли;
			Исключение			
			КонецПопытки;
			
			МассивЗаданийКУдалению.Добавить(ФоновоеЗадание);
		КонецЦикла;
		
		//Удаление уже расчитаных метрик из массива контроля
		Для Каждого ЗаданиеКУдалению Из МассивЗаданийКУдалению Цикл
			МассивФоновыхЗаданий.Удалить(МассивФоновыхЗаданий.Найти(ЗаданиеКУдалению));
		КонецЦикла;
		
		//Если нечего больше ждать - завершаем общее ожидание
		Если НЕ МассивФоновыхЗаданий.Количество() Тогда
			Прервать;
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат МетрикиСтрокой;
		      	
КонецФункции

Функция СформироватьМетрикиСинхронно(Выборка, МетодПолученияМетрики)
	
	СтрокаМетрик = "";
		                      		
	Пока Выборка.Следующий() Цикл
		
		Если НЕ Выборка.Расчитывать Тогда
			Продолжить;
		КонецЕсли;
				
		ДатаНачалаРасчета = ТекущаяДата();
		ДатаНачалаРасчетаВМиллисекундах = ТекущаяУниверсальнаяДатаВМиллисекундах();
		
		сткВозврат = СформироватьМетрику(Выборка.Алгоритм);
		Если сткВозврат.Ошибка Тогда
			Продолжить;
		КонецЕсли;
		
		сткВозврат = ПривестиТаблицуРасчетаМетрикиКСтрокеPrometheus(Выборка.ИмяМетрики, Выборка.ТипМетрики, сткВозврат.МетрикаТаблицей);
		Если сткВозврат.Ошибка Тогда
			Продолжить;
		КонецЕсли;
		
		СтрокаМетрик = СтрокаМетрик + сткВозврат.МетрикаСтрокой; 
		
		ЗаписатьИнформациюОРасчетеМетрикиФоновымЗаданием(Выборка.Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаНачалаРасчета);
		
	КонецЦикла;
	
	Возврат СтрокаМетрик;
		
КонецФункции

Процедура СформироватьМетрикуФоновымЗаданием(ИмяМетрики, ТипМетрики, Алгоритм, ИдентификаторХранилища, Метрика) Экспорт
	
	ДатаНачалаРасчета = ТекущаяДата();
	ДатаНачалаРасчетаВМиллисекундах = ТекущаяУниверсальнаяДатаВМиллисекундах();
		
	сткВозврат = СформироватьМетрику(Алгоритм);
	Если сткВозврат.Ошибка Тогда
		ПоместитьВоВременноеХранилище(сткВозврат, ИдентификаторХранилища);
		Возврат;
	КонецЕсли;
	
	сткВозврат = ПривестиТаблицуРасчетаМетрикиКСтрокеPrometheus(ИмяМетрики, ТипМетрики, сткВозврат.МетрикаТаблицей);
	Если сткВозврат.Ошибка Тогда
		ПоместитьВоВременноеХранилище(сткВозврат, ИдентификаторХранилища);
		Возврат;
	КонецЕсли;
	
	ПоместитьВоВременноеХранилище(сткВозврат, ИдентификаторХранилища);
	ЗаписатьИнформациюОРасчетеМетрикиФоновымЗаданием(Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаНачалаРасчета);
	
КонецПроцедуры

Функция СформироватьМетрику(Алгоритм) Экспорт
	
	сткВозврат = Новый Структура;
	сткВозврат.Вставить("МетрикаТаблицей",Новый ТаблицаЗначений);
	сткВозврат.Вставить("ОписаниеОшибки","");
	сткВозврат.Вставить("Ошибка",Ложь);
	
	ТаблицаЗначений = Новый ТаблицаЗначений;
	
	Попытка
		Выполнить(Алгоритм);
	Исключение
		ОписаниеОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Prometheus data exporter",
			УровеньЖурналаРегистрации.Ошибка,
			,
			,
			ОписаниеОшибки);
		сткВозврат.Ошибка = Истина;
		сткВозврат.ОписаниеОшибки = ОписаниеОшибки;
		Возврат сткВозврат;
	КонецПопытки;
	
	сткВозврат.МетрикаТаблицей = ТаблицаЗначений;
	
	Возврат сткВозврат;
		
КонецФункции

Функция ПривестиТаблицуРасчетаМетрикиКСтрокеPrometheus(ИмяМетрики, ТипМетрики, МетрикаТаблицейЗначений) Экспорт
	
	сткВозврат = Новый Структура();
	сткВозврат.Вставить("МетрикаСтрокой","");
	сткВозврат.Вставить("Ошибка",Ложь);
	сткВозврат.Вставить("ОписаниеОшибки","");
	
	Если НЕ МетрикаТаблицейЗначений.Количество() Тогда
		сткВозврат.Ошибка = Истина;
		сткВозврат.ОписаниеОшибки = "Пустая метрика";
		Возврат сткВозврат;
	КонецЕсли;
	
	Попытка
	
		ЗаписьJSON = Новый ЗаписьJSON;
		ЗаписьJSON.УстановитьСтроку();
	
		Если ЗначениеЗаполнено(ТипМетрики) Тогда
			ЗаписьJSON.ЗаписатьБезОбработки("# TYPE ");
			ЗаписьJSON.ЗаписатьБезОбработки(ИмяМетрики);
			ЗаписьJSON.ЗаписатьБезОбработки(" ");
			ЗаписьJSON.ЗаписатьБезОбработки(Метаданные.Перечисления.пэмТипыМетрик.ЗначенияПеречисления[Перечисления.пэмТипыМетрик.Индекс(ТипМетрики)].Синоним);
			ЗаписьJSON.ЗаписатьБезОбработки(Символы.ПС);
		КонецЕсли; 
	
		Для Каждого Строка Из МетрикаТаблицейЗначений Цикл
		
			ЗаписьJSON.ЗаписатьБезОбработки(ИмяМетрики);
			ЗаписьJSON.ЗаписатьБезОбработки("{");

			ВыводительРазделитель = Неопределено;
		
			Для Каждого Колонка Из МетрикаТаблицейЗначений.Колонки Цикл
				Если Колонка.Имя = "value" Тогда
					Продолжить;
				КонецЕсли;
			
				Если ВыводительРазделитель = Истина Тогда
					ЗаписьJSON.ЗаписатьБезОбработки(", ");
				КонецЕсли;  
			
				ЗаписьJSON.ЗаписатьБезОбработки(Колонка.Имя);
				ЗаписьJSON.ЗаписатьБезОбработки("=""");
				ЗаписьJSON.ЗаписатьБезОбработки(Строка[Колонка.Имя]);
				ЗаписьJSON.ЗаписатьБезОбработки("""");
			
				Если ВыводительРазделитель = Неопределено Тогда
				    ВыводительРазделитель  = Истина;
				КонецЕсли;  
			
			КонецЦикла; 
		
			ЗаписьJSON.ЗаписатьБезОбработки("} ");
			ЗаписьJSON.ЗаписатьБезОбработки(Строка(Формат(Строка["value"],"ЧРГ=; ЧН=; ЧГ=")));
			ЗаписьJSON.ЗаписатьБезОбработки(Символы.ПС);
		
		КонецЦикла;
	Исключение
		ОписаниеОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Prometheus data exporter",
			УровеньЖурналаРегистрации.Ошибка,
			,
			,
			ОписаниеОшибки);
		сткВозврат.Ошибка = Истина;
		сткВозврат.ОписаниеОшибки = ОписаниеОшибки;
		Возврат сткВозврат;
	КонецПопытки;
	
	сткВозврат.МетрикаСтрокой = ЗаписьJSON.Закрыть();
		  	
	Возврат сткВозврат;

КонецФункции

//Таймаут - число. Квант равеен 1 секунде
Процедура Пауза(Знач Таймаут) Экспорт

	СистемнаяИнформация = Новый СистемнаяИнформация(); 
	ЭтоWindows = (СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Windows_x86) 
	Или (СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Windows_x86_64); 
	
	Таймаут = Таймаут + 1;

	Если ЭтоWindows Тогда 
		ШаблонКоманды = "ping 127.0.0.1 -n " + Таймаут + " -w 1000"; 
	Иначе 
		ШаблонКоманды = "ping -c " + Таймаут + " -w 1000 127.0.0.1"; 
	КонецЕсли; 
	
	ЗапуститьПриложение(ШаблонКоманды,,Истина);
	
КонецПроцедуры

Процедура ЗаписатьИнформациюОРасчетеМетрикиФоновымЗаданием(Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаНачалаРасчета)
	
		МассивПараметровРасчетаМетрик = Новый Массив;
		МассивПараметровРасчетаМетрик.Добавить(Метрика);
		МассивПараметровРасчетаМетрик.Добавить(ДатаНачалаРасчетаВМиллисекундах);
		МассивПараметровРасчетаМетрик.Добавить(ТекущаяУниверсальнаяДатаВМиллисекундах());
		МассивПараметровРасчетаМетрик.Добавить(ДатаНачалаРасчета);
		ФоновыеЗадания.Выполнить("пэмМетрикиСервер.ЗаписатьИнформациюОРасчетеМетрики",МассивПараметровРасчетаМетрик);	
		
КонецПроцедуры

Процедура ЗаписатьИнформациюОРасчетеМетрики(Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаОкончанияРасчетаВМиллисекундах, ДатаНачалаРасчета) Экспорт
	
	МенеджерЗаписи = РегистрыСведений.пэмСостояниеМетрик.СоздатьМенеджерЗаписи();
	МенеджерЗаписи.Метрика = Метрика; 
	МенеджерЗаписи.Прочитать();
	
	МенеджерЗаписи.Метрика = Метрика;
	МенеджерЗаписи.ДатаРасчета = ДатаНачалаРасчета;
	МенеджерЗаписи.Длительность = ДатаОкончанияРасчетаВМиллисекундах - ДатаНачалаРасчетаВМиллисекундах;
		
	МенеджерЗаписи.Записать();
	
КонецПроцедуры

//Маска - текстовая строка. Допустимы следующие символы:
// . - любой символ
// + - один или более раз, пример ".+" - один или более любой символ.
// * - ноль или более раз, пример ".*" - любое количество любых символов (даже ни одного).
// [n-m] - символ от m до n. Например: [a-zA-Z_:]* - строка любой длины, состоящая из больших и маленьких латинских символов, знаков "_" и ":" , Еще пример: "[0-9]+" - одна или более цифр(а).
// \d - цифра, пример 
// \d+ - одна или более цифр(а).
// \D - не цифра.
// \s - пробельный символ - ТАБ, пробел, перенос строки, возврат каретки и т.п.
// \S - непробельный символ.
// \w - буква, цифра, подчеркивание.
// \W - не буква, не цифра и не подчеркивание соответственно.
// ^ - начало текста, например "^\d+" - строка начинается с цифры.
// $ - конец текста, например "\D+$" - строка заканчивается НЕ цифрой.
// {m,n} - шаблон для от m до n символов, например "\d{2,4}" - от двух до четырех цифр. Можно указать одну и всего цифру для строгого соответвия.
// \ - экранирует спецсимволы. Например, "\." - символ точки.
Функция ПроверитьСтрокуНаСоответствиеМаске(Строка, Маска) Экспорт
	
	сткВозврат = Новый Структура;
	сткВозврат.Вставить("ЕстьОшибка",Истина);
	сткВозврат.Вставить("ОписаниеОшибки", "Ошибка в коде");
	сткВозврат.Вставить("Результат",Неопределено);
		
    Чтение = Новый ЧтениеXML;
    Чтение.УстановитьСтроку(
                "<Model xmlns=""http://v8.1c.ru/8.1/xdto"" xmlns:xs=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xsi:type=""Model"">
                |<package targetNamespace=""sample-my-package"">
                |<valueType name=""testtypes"" base=""xs:string"">
                |<pattern>" + Маска + "</pattern>
                |</valueType>
                |<objectType name=""TestObj"">
                |<property xmlns:d4p1=""sample-my-package"" name=""TestItem"" type=""d4p1:testtypes""/>
                |</objectType>
                |</package>
                |</Model>");

    Модель = ФабрикаXDTO.ПрочитатьXML(Чтение);
	
	Попытка
    	МояФабрикаXDTO = Новый ФабрикаXDTO(Модель);
	Исключение
		сткВозврат.ЕстьОшибка = Истина;
		сткВозврат.ОписаниеОшибки = "Ошибка маски";
		Возврат сткВозврат;
	КонецПопытки;
		
    Пакет = МояФабрикаXDTO.Пакеты.Получить("sample-my-package");
    Тест = МояФабрикаXDTO.Создать(Пакет.Получить("TestObj"));

    Попытка
        Тест.TestItem = Строка;
    Исключение
        сткВозврат.ЕстьОшибка = Истина;
		сткВозврат.ОписаниеОшибки = "Строка не соответствует маске";
		сткВозврат.Результат = Ложь;
		Возврат сткВозврат;
	КонецПопытки;
	
	сткВозврат.ЕстьОшибка = Ложь;
	сткВозврат.ОписаниеОшибки = "";
	сткВозврат.Результат = Истина;
    Возврат сткВозврат;
   
КонецФункции

#КонецОбласти