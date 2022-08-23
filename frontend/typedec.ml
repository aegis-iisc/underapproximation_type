open Ocaml_parser
open Parsetree
open Languages.Typedec

let constructor_declaration_of_ocaml { pcd_name; pcd_args; _ } =
  let argsty =
    match pcd_args with
    | Pcstr_tuple cts -> List.map Type.core_type_to_t cts
    | _ -> failwith "unimp complex type decl"
  in
  { constr_name = pcd_name.txt; argsty }

let constructor_declaration_to_ocaml { constr_name; argsty } =
  {
    pcd_name = Location.mknoloc constr_name;
    (* pcd_vars = Location.mknoloc []; *)
    pcd_args = Pcstr_tuple (List.map Type.t_to_core_type argsty);
    pcd_res = None;
    pcd_loc = Location.none;
    pcd_attributes = [];
  }

let of_ocamltypedec { ptype_name; ptype_params; ptype_kind; ptype_manifest; _ }
    =
  match (ptype_params, ptype_kind, ptype_manifest) with
  | [], Ptype_variant cds, None ->
      {
        type_name = ptype_name.txt;
        type_decls = List.map constructor_declaration_of_ocaml cds;
      }
  | _ -> failwith "unimp complex type decl"

let to_ocamltypedec { type_name; type_decls } =
  {
    ptype_name = Location.mknoloc type_name;
    ptype_params = [];
    ptype_cstrs = [];
    ptype_kind =
      Ptype_variant (List.map constructor_declaration_to_ocaml type_decls);
    ptype_manifest = None;
    ptype_attributes = [];
    ptype_loc = Location.none;
    ptype_private = Asttypes.Public;
  }

let layout_ocaml es =
  let _ = Format.flush_str_formatter () in
  Pprintast.structure Format.str_formatter
  @@ List.map
       (fun e ->
         {
           pstr_desc = Pstr_type (Asttypes.Recursive, [ e ]);
           pstr_loc = Location.none;
         })
       es;
  Format.flush_str_formatter ()

let layout e = layout_ocaml @@ List.map to_ocamltypedec e
