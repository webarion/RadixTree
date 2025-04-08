

; ░█▀▄░█▀█░█▀▄░▀█▀░█░█░░░▀█▀░█▀▄░█▀▀░█▀▀ algorithm
; ░█▀▄░█▀█░█░█░░█░░▄▀▄░░░░█░░█▀▄░█▀▀░█▀▀
; ░▀░▀░▀░▀░▀▀░░▀▀▀░▀░▀░░░░▀░░▀░▀░▀▀▀░▀▀▀

; Description .: Implementation of the Radix Tree algorithm for Purebasic
;              : Реализация алгоритма Radix Tree для PureBasic
; Author ......: Webarion
; Link ........: https://github.com/webarion/RadixTree/blob/main/RadixTree.pb
; License .....: Free license, do what you want! Свободная лицензия, делай то, что хочешь!
; Version .....: 1.3


;- History:
;   v1.3 - In the Delete procedure, a error with the absence of a returned value of a remote key is fixed. An example of removal is updated.
;   v1.2 - Small code adjustments are made.
;   v1.1 - Some corrections, optimization are made. Added the procedure for removing the key.
;   v1.0 - The first published version.

; История версий:
;   v1.3 - В процедуре Delete, исправлена ошибка с отсутствием возвращаемого параметра удалённого ключа. Обновлён пример удаления.
;   v1.2 - Сделаны небольшие корректировки кода.
;   v1.1 - Сделана, небольшая оптимизация. Добавлена процедура удаления ключа.
;   v1.0 - Первая опубликованная версия


DeclareModule RadixTree
  
  EnableExplicit 
  
  ;- Available to the user structure. Доступные для пользователя структуры
  
  Structure Key
    Key$
    *Value
  EndStructure
  
  
  ;- DECLARES of user procedures and a short description. Объявление пользовательских процедур и короткое описание
  
  Declare   New()                      ; Creates a new Radix Tree.              Создаёт новый Radix Tree
  Declare   Free( *Root )              ; Frees the entire memory of Radix Tree. Освобождает всю память Radix Tree
  Declare   Set( *Root, Key$, *Value ) ; Writes key data to Radix Tree.         Записывает данные ключа в Radix Tree
  Declare   Get( *Root, Key$         ) ; Returns the key data.                  Возвращает данные ключа
  Declare   Delete( *Root, Key$ )      ; Removes the key from Radix Tree.       Удаляет ключ из Radix Tree
  Declare   CountKeys( *Root )         ; Returns the number of keys existing in Radix Tree. Возвращает количество ключей, существующих в Radix Tree
  Declare.a PrefixList( *Root, Prefix$, List Key.Key() ) ; Gets the keys to the prefix. Получает ключи по префиксу
  Declare   AllKeys( *Root, List Key.Key() )             ; He gets all the keys. Получает все ключи 
  
  
  ; This is mainly for tests. If you need a tree depth for something, install #radixtree_enable_procedure_depth = 1, in the compiler settings
  ; В основном, это для тестов. Если вам для чего-то нужна глубина дерева, установите #RadixTree_Enable_Procedure_Depth = 1, в настройках компилятора
  CompilerIf Defined( RadixTree_Enable_Procedure_Depth, #PB_Constant )
    Declare Depth( *Root ) ; Returns the depth of Radix Tree from the specified node. Возвращает глубину Radix Tree от указанного узла
  CompilerEndIf
  
  
EndDeclareModule



Module RadixTree
  
  ;- Internal Structures. Приватные структуры
  Structure Symbol
    c.c[0]
  EndStructure
  
  Structure Node
    *Child.Node   
    *Next.Node
    *Value
    Pref$
  EndStructure
  
  
  ;- INTERNAL PROCEDURES. ВНУТРЕННИЕ СИСТЕМНЫЕ ПРОЦЕДУРЫ
  
  
  ; Внутренняя рекурсивная процедура для сбора всех ключей, начиная с указанного узла
  Procedure _CollectKeys( *Node.Node, List Key.Key(), CurrentPrefix$ = "" )
    While *Node
      Protected FullPrefix$ = CurrentPrefix$ + *Node\Pref$
      If *Node\Value
        AddElement( Key() )
        Key()\Key$  = FullPrefix$
        Key()\Value = *Node\Value
      EndIf  
      _CollectKeys( *Node\Child, Key(), FullPrefix$ )
      *Node = *Node\Next
    Wend
  EndProcedure  
  
  
  ;- USER PROCEDURES. ПОЛЬЗОВАТЕЛЬСКИЕ ПРОЦЕДУРЫ
  
  
  ; Creates a new root node Radix Tree and returns the pointer to it
  ; Создаёт новый корневой узел Radix Tree и возвращает указатель на него
  Procedure New()
    Protected *New.Node = AllocateStructure(Node)
    *New\Pref$ = ""
    ProcedureReturn *New
  EndProcedure
  
  
  ; Writes the key data in Radix Tree
  ; Записывает данные ключа в Radix Tree
  Procedure Set( *Node.Node, Key$, *Value )
    If Not *Value : ProcedureReturn : EndIf
    Key$ = LCase(Key$)
    Protected *SearchPref.Symbol = @Key$
    
    While *SearchPref\c
      
      ; поиск по первому символу
      While *Node
        Protected *ExistingPref.Symbol = @*Node\Pref$
        If *ExistingPref\c = *SearchPref\c Or Not *Node\Next
          Break
        EndIf
        *Node = *Node\Next ; к поиску следующего первого символа
      Wend
      
      If *ExistingPref\c = *SearchPref\c; первые символы совпадают
        Protected i = 1                 ; далее сравниваем со второго символа
        While *SearchPref\c[i] And *ExistingPref\c[i] And *SearchPref\c[i] = *ExistingPref\c[i]
          i + 1
        Wend
        
        If Not *ExistingPref\c[i] ; существующий префикс закончен, но искомый ключ, может быть не закончен
          
          If *SearchPref\c[i]     ; искомый ключ не закончен
            
            If *Node\Child   ; дочерний существует, проверяем в дочерних
              *Node = *Node\Child
              *SearchPref = @*SearchPref\c[i]
              Continue
            Else ; дочернего нет, создаём и записываем
              *Node\Child = AllocateStructure(Node)
              *Node\Child\Pref$ = PeekS( @*SearchPref\c[i] ) ; в дочерний, записывается правая часть искомого префикса
              *Node\Child\Value = *Value
            EndIf
            
          Else ; ключ уже существует, обновляем данные
            *Node\Value = *Value 
            ProcedureReturn
          EndIf
          
          ProcedureReturn
        Else ; существующий префикс не закончен 
          
          Protected *New.Node = AllocateStructure(Node)
          *New\Pref$  = PeekS( @*ExistingPref\c[i] ) ; записывается правая часть существующего префикса
          *New\Value  = *Node\Value   
          If *Node\Child ; есть дочерний
            *New\Child = *Node\Child
          EndIf
          *Node\Child  = *New
          *Node\Pref$  = PeekS( *ExistingPref, i ) ; записывается левая часть существующего префикса
          *Node\Value  = 0  
          If *SearchPref\c[i] ; искомый префикс не закончен
            *New        = AllocateStructure(Node)
            *New\Pref$  = PeekS( @*SearchPref\c[i] ) ; записывается правая часть искомого префикса
            *New\Value  = *Value
            *New\Next   = *Node\Child
            *Node\Child = *New
          Else ; ключ найден, обновляем данные
            *Node\Value = *Value
          EndIf
          
          ProcedureReturn
        EndIf
        
      Else ; узел не найден, а *Node указывает на последний узел в текущей Next последовательности узлов
        
        If *Node\Pref$ ; если у узла есть ключ, то это не корневой узел, в ином случае запись в корень, без создания структуры
          *Node\Next = AllocateStructure(Node)
          *Node = *Node\Next
        EndIf
        *Node\Pref$ = PeekS( *SearchPref )
        *Node\Value = *Value
        
        ProcedureReturn
      EndIf
      
    Wend
    
  EndProcedure
  
  
  ; Returns the key data
  ; Возвращает данные ключа
  Procedure Get( *Node.Node, Key$ )
    Key$ = LCase(Key$)
    Protected *SearchPref.Symbol = @Key$
    
    While *SearchPref\c
      
      While *Node
        Protected *ExistingPref.Symbol = @*Node\Pref$
        If *ExistingPref\c = *SearchPref\c
          Break
        EndIf
        *Node = *Node\Next ; к поиску следующего первого символа
      Wend
      
      If *Node
        Protected i = 1 ; далее со второго символа
        While *SearchPref\c[i] And *ExistingPref\c[i] And *SearchPref\c[i] = *ExistingPref\c[i]
          i+1
        Wend
        If Not *ExistingPref\c[i] ; существующий префикс совпадает с искомым, но искомый ключ, может быть не закончен
          If *SearchPref\c[i]     ; искомый ключ не закончен
            *Node       = *Node\Child
            *SearchPref = @*SearchPref\c[i]
          Else ; ключ найден, возвращаем результат
            ProcedureReturn *Node\Value
          EndIf
        Else
          ProcedureReturn 0
        EndIf
      Else ; не найдено
        ProcedureReturn 0
      EndIf
      
    Wend
    
    ProcedureReturn 0
  EndProcedure
  
  
  ; Removes the key, will return 1 in case of successful removal of the key and 0 - if the key does not exist.
  
  ; Удаляет ключ, и возвращает данные удалённого ключа. Если ключа не существовало, возвращает 0.
  
  Procedure Delete( *Node.Node, Key$ )
    Key$ = LCase(Key$)
    Protected *SearchPref.Symbol = @Key$
    Protected *Parent.Node = 0
    Protected *Prev.Node = 0
    While *SearchPref\c
      ; Поиск узла с совпадающим первым символом
      While *Node
        Protected *ExistingPref.Symbol = @*Node\Pref$
        If *ExistingPref\c = *SearchPref\c Or Not *Node\Next
          Break
        EndIf
        *Prev = *Node
        *Node = *Node\Next
      Wend
      If *Node ; узел с первым символом найден
        Protected i = 1
        While *SearchPref\c[i] And *ExistingPref\c[i] And *SearchPref\c[i] = *ExistingPref\c[i] ; продолжаем со второго символа
          i + 1
        Wend
        If Not *ExistingPref\c[i] ; Существующий префикс совпадает с искомым
          If *SearchPref\c[i]     ; Искомый ключ не закончен
            *Parent = *Node
            *Node = *Node\Child
            *SearchPref = @*SearchPref\c[i]
            Continue
          Else ; Ключ найден
            Protected *ReturnVal = 0
            If *Node\Child ; Если есть дочерние узлы обнуляем Value
              If *Node\Value ; это ключ
                *ReturnVal = *Node\Value
                *Node\Value = 0
              Else ; а это пустой узел
                ProcedureReturn 0
              EndIf
            Else ; Если дочерних узлов нет, удаляем узел
              If *Parent
                If *Prev
                  *Prev\Next = *Node\Next
                Else
                  *Parent\Child = *Node\Next
                EndIf
              Else
                If *Prev
                  *Prev\Next = *Node\Next
                Else
                  *Node = *Node\Next
                EndIf
              EndIf
              *ReturnVal = *Node\Value
              FreeStructure(*Node)
            EndIf
            ProcedureReturn *ReturnVal
          EndIf
        Else
          ProcedureReturn #False
        EndIf
      Else
        ProcedureReturn #False
      EndIf
    Wend
    
    ProcedureReturn #False
  EndProcedure
  
  
  ; Frees the entire memory of Radix Tree. *Node - pointer to the root node
  ; Освобождает всю память Radix Tree. *Node - указатель на корневой узел
  Procedure Free( *Node.Node )
    While *Node
      Free( *Node\Child )
      Protected *Next = *Node\Next
      FreeStructure(*Node)
      *Node = *Next
    Wend
  EndProcedure
  
  
  ; Gets all the keys Radix Tree
  ; Получает все ключи Radix Tree
  Procedure AllKeys( *Root.Node, List Key.Key() )
    ClearList( Key() )
    _CollectKeys( *Root, Key() )
  EndProcedure
  
  
  ; Gets the keys to the prefix
  ; Получает ключи по префиксу 
  Procedure.a PrefixList( *Node.Node, Prefix$, List Key.Key() )
    Protected FirstChars$ = ""
    Prefix$ = LCase(Prefix$)
    Protected *SearchPref.Symbol = @Prefix$
    While *Node
      Protected *ExistingPref.Symbol = @*Node\Pref$
      Protected i = 0
      While *SearchPref\c[i] And *ExistingPref\c[i] And *SearchPref\c[i] = *ExistingPref\c[i]
        i + 1
      Wend
      If i ; есть совпадение префикса, в текущей *Next последовательности
        If *SearchPref\c[i]
          FirstChars$ + PeekS( @*Node\Pref$, i )
          *Node       = *Node\Child
          *SearchPref = @*SearchPref\c[i]
          Continue
        Else
          ClearList( Key() )
          If *Node\Value
            AddElement( Key() )
            Key()\Key$  = FirstChars$ + *Node\Pref$
            Key()\Value = *Node\Value
          EndIf
          _CollectKeys( *Node\Child, Key(), FirstChars$ + *Node\Pref$ )
          ProcedureReturn #True
        EndIf
      EndIf
      *Node = *Node\Next ; к следующей текущей *Next последовательности префиксов
    Wend
    ProcedureReturn #False
  EndProcedure
  
  
  ; Returns the number of keys existing in Radix Tree
  ; Возвращает количество ключей, существующих в Radix Tree
  Procedure CountKeys( *Node.Node )
    Protected Count = 0
    While *Node 
      If *Node\Value
        Count + 1
      EndIf
      If *Node\Child
        Count + CountKeys( *Node\Child )
      EndIf
      *Node = *Node\Next
    Wend
    ProcedureReturn Count
  EndProcedure
  
  
  CompilerIf Defined( RadixTree_Enable_Procedure_Depth, #PB_Constant )
    ; Returns the depth of Radix Tree
    ; Возвращает глубину Radix Tree
    Procedure Depth( *Node.Node )
      Protected Depth = 1, ChildDepth = 0
      While *Node
        If *Node\Child
          ChildDepth = Depth( *Node\Child )
        EndIf
        *Node = *Node\Next
      Wend  
      ProcedureReturn Depth + ChildDepth
    EndProcedure
  CompilerEndIf
  
  
  DisableExplicit
  
  
EndModule


;- EXAMPLE. ПРИМЕР
CompilerIf #PB_Compiler_IsMainFile
  
  
  ;--    Creating a root node. Создание корневаого узла
  Define *Root = RadixTree::New()
  
  
  ;--    Set keys. Запись ключей
  RadixTree::Set( *Root, "Жизнь",    101 )
  RadixTree::Set( *Root, "Живот",    102 )
  RadixTree::Set( *Root, "Живица",   103 )
  RadixTree::Set( *Root, "Жизненно", 104 )
  RadixTree::Set( *Root, "Живой",    105 )
  
  RadixTree::Set( *Root, "Romane",     201 )
  RadixTree::Set( *Root, "Romanus",    202 )
  RadixTree::Set( *Root, "Romulus",    203 )
  RadixTree::Set( *Root, "Rubens",     204 )
  RadixTree::Set( *Root, "Ruber",      205 )
  RadixTree::Set( *Root, "Rubicon",    206 )
  RadixTree::Set( *Root, "Rubicundus", 207 ) 
  RadixTree::Set( *Root, "Rubic", 208 ) 
  
  ;--    Get keys. Чтение ключей
  Debug "Get key 'Жизнь': "      + RadixTree::Get( *Root, "Жизнь" )
  Debug "Get key 'Romane': "     + RadixTree::Get( *Root, "Romane" )
  Debug "Get key 'Romanus': "    + RadixTree::Get( *Root, "Romanus" )
  Debug "Get key 'Romulus': "    + RadixTree::Get( *Root, "Romulus" )
  Debug "Get key 'Rubens': "     + RadixTree::Get( *Root, "Rubens" )
  Debug "Get key 'Ruber': "      + RadixTree::Get( *Root, "Ruber" )
  Debug "Get key 'Rubicon': "    + RadixTree::Get( *Root, "Rubicon" )
  Debug "Get key 'Rubicundus': " + RadixTree::Get( *Root, "Rubicundus" )
  
  ; Non -existing keys. Несуществующие ключи
  Debug "Get key 'Жива': " + RadixTree::Get( *Root, "Жива" )
  Debug "Get key 'Ruby': " + RadixTree::Get( *Root, "Ruby" )
  
  Debug "Count keys: " + RadixTree::CountKeys( *Root ) ; The number of keys. Количество ключей
  
  CompilerIf Defined( RadixTree_Enable_Procedure_Depth, #PB_Constant )
    Debug "Depth: " + RadixTree::Depth( *Root )  ; The depth of the tree. Глубина дерева.
  CompilerEndIf
  
  
  ;--    List of keys on the prefix. Список ключей по префиксу
  Define NewList ListRT.RadixTree::Key()
  Define PrefList$ = "Ru"
  Debug "----- PrefList$: " + PrefList$
  RadixTree::PrefixList( *Root, PrefList$, ListRT() )
  ForEach ListRT()
    Debug "     " + ListRT()\Key$ + " = " + Str( ListRT()\Value )
  Next 
  
  
  ;--    An example of removing the key. Пример удаления ключа.
  Debug "----- Example Delete key: " 
  
  Structure MyTestObject
    ID.i
  EndStructure
  
  Procedure New_MyTestObject(ID)
    Protected *MyTestObject.MyTestObject = AllocateStructure(MyTestObject)
    *MyTestObject\ID = ID
    ProcedureReturn *MyTestObject
  EndProcedure
  
  ; Create the key that we will delete. Создаём ключ, который будем удалять
  RadixTree::Set( *Root, "Romantic", New_MyTestObject(209) ) 
  Debug "Key 'Romantic' = " + RadixTree::Get( *Root, "Romantic" )
  
  ; When removing, we get a pointer to a test object to free the memory of this object
  ; При удалении, получаем указатель на тестовый объект, чтобы освободить память этого объекта
  Define *MyTestObject = RadixTree::Delete( *Root, "Romantic" )

  If *MyTestObject
    FreeStructure(*MyTestObject)
    Debug "The key 'Romantic' is deleted"  
  Else
    Debug "Key Romantic was not found"
  EndIf
  
  Debug "Returned from Delete: " + Str(*MyTestObject)
  
  ; Removal check. Проверка удаления
  Debug "Get key 'Romantic': " + RadixTree::Get( *Root, "Romantic" )
  
  
  ;--    Get all keys. Список всех ключей
  Debug "----- AllKeys: "
  RadixTree::AllKeys( *Root, ListRT() )
  ForEach ListRT()
    Debug "     " + ListRT()\Key$ + " = " + Str( ListRT()\Value )
  Next 
  
  
  ;--    Free the Radix Tree memory. Освобождение памяти Radix Tree.
  RadixTree::Free( *Root )
  
  
CompilerEndIf


