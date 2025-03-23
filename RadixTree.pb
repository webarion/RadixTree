

; ░█▀▄░█▀█░█▀▄░▀█▀░█░█░░░▀█▀░█▀▄░█▀▀░█▀▀ algorithm
; ░█▀▄░█▀█░█░█░░█░░▄▀▄░░░░█░░█▀▄░█▀▀░█▀▀
; ░▀░▀░▀░▀░▀▀░░▀▀▀░▀░▀░░░░▀░░▀░▀░▀▀▀░▀▀▀

; Author ......: Webarion
; Link ........: https://github.com/webarion/RadixTree/blob/main/RadixTree.pb
; License .....: Free license, do what you want! Свободная лицензия, делай то, что хочешь!
; Version .....: 1.1
; Note ........: This standard Radix Tree algorithm does not have sorting in alphabetical order, while it is very fast.
; Примечание ..: Это стандартный алгоритм Radix Tree, не имеет сортировки в алфавитном порядке, при этом является очень быстрым.

; History:
;   v1.1 - Some corrections, optimization are made. Added the procedure for removing the key.
;          Сделана, небольшая оптимизация. Добавлена процедура удаления ключа.
;   v1.0 - The first published version. Первая опубликованная версия


DeclareModule RadixTree
  
  EnableExplicit 
  
  ; This is mainly for tests. If you need a tree depth for something, install Constant in #true
  ; В основном, это для тестов. Если вам для чего-то нужна глубина дерева, установите константу в #True
  #RadixTree_Enable_Procedure_Depth = #False 
  
  ;- Available to the user structure. Доступные для пользователя структуры
  
  Structure Key
    Key$
    *Value
  EndStructure
  
  
  ;- DECLARES of user procedures and a short description. Объявление пользовательских процедур и короткое описание
  
  Declare New()                      ; Creates a new Radix Tree.              Создаёт новый Radix Tree
  Declare Free( *Root )              ; Frees the entire memory of Radix Tree. Освобождает всю память Radix Tree
  Declare Set( *Root, Key$, *Value ) ; Writes key data to Radix Tree.         Записывает данные ключа в Radix Tree
  Declare Get( *Root, Key$         ) ; Returns the key data.                  Возвращает данные ключа
  Declare Delete( *Root, Key$ )      ; Removes the key from Radix Tree.       Удаляет ключ из Radix Tree
  Declare CountKeys( *Root )         ; Returns the number of keys existing in Radix Tree. Возвращает количество ключей, существующих в Radix Tree
  Declare PrefixList( *Root, Prefix$, List Key.Key() ) ; Gets the keys to the prefix. Получает ключи по префиксу
  Declare AllKeys( *Root, List Key.Key() ) ; He gets all the keys. Получает все ключи.  

  CompilerIf #RadixTree_Enable_Procedure_Depth
    Declare Depth( *Root ) ; Returns the depth of Radix Tree from the specified node. Возвращает глубину Radix Tree от указанного узла
  CompilerEndIf
  
EndDeclareModule



Module RadixTree
  
  ;- Internal Structures. Приватные структуры
  Structure Symbol
    c.c[0]
  EndStructure
  
  Structure RadixTree
    *Child.RadixTree   
    *Next.RadixTree
    *Value
    Pref$
  EndStructure
  
  
  ;- INTERNAL PROCEDURES. ВНУТРЕННИЕ СИСТЕМНЫЕ ПРОЦЕДУРЫ
  
  
  ; Внутренняя рекурсивная процедура для сбора всех ключей, начиная с указанного узла
  Procedure _CollectKeys( *Node.RadixTree, List Key.Key(), CurrentPrefix$ = "" )
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
    Protected *New.RadixTree = AllocateStructure(RadixTree)
    *New\Pref$ = ""
    ProcedureReturn *New
  EndProcedure
  
  
  ; Writes the key data in Radix Tree
  ; Записывает данные ключа в Radix Tree
  Procedure Set( *Node.RadixTree, Key$, *Value )
    If Not *Value : Delete( *Node, Key$ ) : EndIf
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
              *Node\Child = AllocateStructure(RadixTree)
              *Node\Child\Pref$ = PeekS( @*SearchPref\c[i] ) ; в дочерний, записывается правая часть искомого префикса
              *Node\Child\Value = *Value
            EndIf
            
          Else ; ключ найден, обновляем данные
            *Node\Value = *Value 
          EndIf
          
          ProcedureReturn
        Else ; существующий префикс не закончен 
          
          Protected *New.RadixTree = AllocateStructure(RadixTree)
          *New\Pref$  = PeekS( @*ExistingPref\c[i] ) ; записывается правая часть существующего префикса
          *New\Value  = *Node\Value   
          If *Node\Child ; есть дочерний
            *New\Child = *Node\Child
          EndIf
          *Node\Child  = *New
          *Node\Pref$  = PeekS( *ExistingPref, i ) ; записывается левая часть существующего префикса
          *Node\Value  = 0  
          If *SearchPref\c[i] ; искомый префикс не закончен
            *New        = AllocateStructure(RadixTree)
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
          *Node\Next = AllocateStructure(RadixTree)
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
  Procedure Get( *Node.RadixTree, Key$ )
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
          ProcedureReturn #Null
        EndIf
      Else ; не найдено
        ProcedureReturn #Null
      EndIf
      
    Wend
    
    ProcedureReturn #Null
  EndProcedure
  
  
  ; Removes the key. Удаляет ключ
  Procedure Delete( *Node.RadixTree, Key$ )
    Key$ = LCase(Key$)
    Protected *SearchPref.Symbol = @Key$
    Protected *Parent.RadixTree = #Null
    Protected *Prev.RadixTree = #Null
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
            If *Node\Child ; Если есть дочерние узлы, просто обнуляем Value
              If *Node\Value ; это ключ
                *Node\Value = 0
              Else ; а это просто узел
                ProcedureReturn #False
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
              FreeStructure(*Node)
            EndIf
            ProcedureReturn #True
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
  Procedure Free( *Node.RadixTree )
    While *Node
      Free( *Node\Child )
      Protected *Next = *Node\Next
      FreeStructure(*Node)
      *Node = *Next
    Wend
  EndProcedure
  
  
  ; Gets all the keys Radix Tree
  ; Получает все ключи Radix Tree
  Procedure AllKeys( *Root.RadixTree, List Key.Key() )
    ClearList( Key() )
    _CollectKeys( *Root, Key() )
  EndProcedure
  
  
  ; Gets the keys to the prefix
  ; Получает ключи по префиксу 
  Procedure PrefixList( *Node.RadixTree, Prefix$, List Key.Key() )
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
      *Node = *Node\Next ; к следующему символу в текущей *Next последовательности префиксов
    Wend
    ProcedureReturn #False
  EndProcedure
  
  
  ; Returns the number of keys existing in Radix Tree
  ; Возвращает количество ключей, существующих в Radix Tree
  Procedure CountKeys( *Node.RadixTree )
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
  
  
  CompilerIf #RadixTree_Enable_Procedure_Depth
    ; Returns the depth of Radix Tree
    ; Возвращает глубину Radix Tree
    Procedure Depth( *Node.RadixTree )
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
  
  CompilerIf RadixTree::#RadixTree_Enable_Procedure_Depth
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
  
  
  ;--    Removing the key. Удаление ключа
  Debug "----- Delete key: "
  Define DelKey$ = "Rubicon"
  If RadixTree::Delete( *Root, DelKey$ )
    Debug "The key '" + DelKey$ + "' is deleted"  
  Else
    Debug "Key '" + DelKey$ + "' was not found"
  EndIf
  ; Проверка удаления
  Debug "Get key '" + DelKey$ + "': " + RadixTree::Get( *Root, DelKey$ )
  
  ; Also, you can delete the key using Radixtree :: Set ( *Root, "Key", 0), but it should be noted that the SET procedure does not return the result of the work. 
  ; If you need a removal result, use Radixtree :: Delete ( *Root, Delkey ​​$)
  ; также, удалить ключ можно с помощью  RadixTree::Set( *Root, "Key", 0 ) , но следует учесть, что процедура Set, не возвращает результат работы. 
  ; Если нужен результат удаления, используйте RadixTree::Delete( *Root, DelKey$ ) 
  
  ;--    Get all keys. Список всех ключей
  Debug "----- AllKeys: "
  RadixTree::AllKeys( *Root, ListRT() )
  ForEach ListRT()
    Debug "     " + ListRT()\Key$ + " = " + Str( ListRT()\Value )
  Next 
  
;   ;  For development. Для разработки.
;   XIncludeFile "..\DrawAlg\DrawAlg.pb" 
;   DrawAlg::Demo_RadixTree( *Root )
  
  ;--    Free the Radix Tree memory. Освобождение памяти Radix Tree.
  RadixTree::Free( *Root )
  
  
CompilerEndIf


