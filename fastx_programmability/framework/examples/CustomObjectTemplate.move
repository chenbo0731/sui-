/// An example of a custom object with comments explaining the relevant bits
module Examples::CustomObjectTemplate {
    use FastX::Address::{Self, Address};
    use FastX::ID::ID;
    use FastX::Transfer;
    use FastX::TxContext::{Self, TxContext};

    /// A custom fastX object. Every object must have the `key` attribute
    /// (indicating that it is allowed to be a key in the fastX global object
    /// pool), and must have a field `id: ID` corresponding to its fastX ObjId.
    /// Other object attributes present at the protocol level (authenticator,
    /// sequence number, TxDigest, ...) are intentionally not exposed here.
    struct Object has key {
        id: ID,
        /// Custom objects can have fields of arbitrary type...
        custom_field: u64,
        /// ... including other objects
        child_obj: ChildObject,
        /// ... and other global objects
        nested_obj: AnotherObject,
    }

    /// An object that can be stored inside global objects or other child
    /// objects, but cannot be placed in the global object pool on its own.
    /// Note that it doesn't need an ID field
    struct ChildObject has store {
        a_field: bool,
    }

    /// An object that can live either in the global object pool or as a nested
    /// object.
    struct AnotherObject has key, store {
        id: ID,
    }

    /// Example of updating an object. All Move fields are private, so the
    /// fields of `Object` can only be (directly) updated by code in this
    /// module.
    public fun write_field(o: &mut Object, v: u64) {
        if (some_conditional_logic()) {
            o.custom_field = v
        }
    }

    /// Example of transferring an object to a a new owner. A struct can only
    /// be transferred by the module that declares it.
    public fun transfer(o: Object, recipient: Address) {
        assert!(some_conditional_logic(), 0);
        Transfer::transfer(o, recipient)
    }

    /// Simple getter
    public fun read_field(o: &Object): u64 {
        o.custom_field
    }

    /// Example of creating a object by deriving a unique ID from the current
    /// transaction and returning it to the caller (who may call functions
    /// from this module to read/write it, package it into another object, ...)
    public fun create(tx: &mut TxContext): Object {
        Object {
            id: TxContext::new_id(tx),
            custom_field: 0,
            child_obj: ChildObject { a_field: false },
            nested_obj: AnotherObject { id: TxContext::new_id(tx) }
        }
    }

    /// Example of an entrypoint function to be embedded in a FastX
    /// transaction. The first argument of an entrypoint is always a
    /// special `TxContext` created by the runtime that is useful for deriving
    /// new id's or determining the sender of the transaction.
    /// After the `TxContext`, entrypoints can take struct types with the `key`
    /// attribute as input, as well as primitive types like ints, bools, ...
    ///
    /// A FastX transaction must declare the ID's of each object it will
    /// access + any primitive inputs. The runtime that processes the
    /// transaction fetches the values associated with the ID's, type-checks
    /// the values + primitive inputs against the function signature of the
    /// `main`, then calls the function with these values.
    ///
    /// If the script terminates successfully, the runtime collects changes to
    /// input objects + created objects + emitted events, increments the
    /// sequence number each object, creates a hash that commits to the
    /// outputs, etc.
    public fun main(
        to_read: &Object,
        to_write: &mut Object,
        to_consume: Object,
        // ... end objects, begin primitive type inputs
        int_input: u64,
        bytes_input: vector<u8>,
        // end primitive types. last arg must be TxContext
        ctx: &mut TxContext,
    ) {
        let v = read_field(to_read);
        write_field(to_write, v + int_input);
        transfer(to_consume, Address::new(bytes_input));
        // demonstrate creating a new object for the sender
        let sender = TxContext::get_signer_address(ctx);
        Transfer::transfer(create(ctx), sender)
    }

    fun some_conditional_logic(): bool {
        // placeholder for checks implemented in arbitrary Move code
        true
    }
}
